/* pdfrx_plus: small addon to pdfrx's existing PDFium worker, protocol v1. */
(() => {
  if (typeof Pdfium === 'undefined' || typeof functions === 'undefined' || typeof disposers === 'undefined') {
    throw new Error('Incompatible pdfrx worker: pdfrx_plus requires the pdfrx 2.6.x worker protocol');
  }
  const supportedAnnotations = new Set([1, 2, 3, 5, 6, 9, 10, 11, 12, 15]);
  const multiply = (a, b) => [a[0]*b[0]+a[2]*b[1], a[1]*b[0]+a[3]*b[1],
    a[0]*b[2]+a[2]*b[3], a[1]*b[2]+a[3]*b[3],
    a[0]*b[4]+a[2]*b[5]+a[4], a[1]*b[4]+a[3]*b[5]+a[5]];
  const point = (m, p) => [m[0]*p[0]+m[2]*p[1]+m[4], m[1]*p[0]+m[3]*p[1]+m[5]];
  function transformedRect(m, r) {
    const p = [[r[0],r[1]], [r[2],r[1]], [r[0],r[3]], [r[2],r[3]]].map(p => point(m, p));
    return [Math.min(...p.map(p=>p[0])), Math.max(...p.map(p=>p[1])),
      Math.max(...p.map(p=>p[0])), Math.min(...p.map(p=>p[1]))];
  }
  function rawToTopLeft(g) {
    const [l,t,r,b] = g.rect;
    return [[1,0,0,-1,-l,t], [0,1,1,0,-b,-l], [-1,0,0,1,r,-b], [0,-1,-1,0,t,r]][g.rotation % 4];
  }
  functions.pdfrxPlusDispatch = function(request) {
    const api = Pdfium.wasmExports;
    const pointers = [];
    const fonts = new Map();
    const alloc = (size) => {
      const p = api.malloc(Math.max(1, size));
      if (!p) throw new Error('PDFium allocation failed');
      pointers.push(p); return p;
    };
    const bytes = data => {
      const a = data instanceof Uint8Array ? data : new Uint8Array(data);
      const p = alloc(a.length); new Uint8Array(Pdfium.memory.buffer, p, a.length).set(a); return p;
    };
    const utf8 = text => bytes(new TextEncoder().encode(String(text) + '\0'));
    const utf16 = text => {
      const p = alloc((text.length + 1) * 2), a = new Uint16Array(Pdfium.memory.buffer, p, text.length + 1);
      for (let i = 0; i < text.length; i++) a[i] = text.charCodeAt(i);
      a[text.length] = 0; return p;
    };
    const f32 = (p, n) => new Float32Array(Pdfium.memory.buffer, p, n);
    const u32 = (p, n) => new Uint32Array(Pdfium.memory.buffer, p, n);
    const check = (ok, action) => { if (!ok) throw new Error(`${action} failed (PDFium ${api.FPDF_GetLastError()})`); };
    const doc = request.handle;
    function geometry(page) {
      const p = alloc(16);
      check(api.FPDF_GetPageBoundingBox(page, p), 'Page box');
      return {rect: Array.from(f32(p, 4)), rotation: api.FPDFPage_GetRotation(page)};
    }
    function string(annot, key) {
      const k = utf8(key), length = api.FPDFAnnot_GetStringValue(annot, k, 0, 0);
      if (length < 2) return null;
      const p = alloc(length); api.FPDFAnnot_GetStringValue(annot, k, p, length);
      const chars = new Uint16Array(Pdfium.memory.buffer, p, length / 2);
      let result = '';
      for (const char of chars) { if (char === 0) break; result += String.fromCharCode(char); }
      return result || null;
    }
    function linkedId(annot, key) {
      const linked = api.FPDFAnnot_GetLinkedAnnot(annot, utf8(key));
      if (!linked) return null;
      try { return string(linked, 'NM'); } finally { api.FPDFPage_CloseAnnot(linked); }
    }
    function annotations(page, sourceDoc = doc) {
      const result = [];
      for (let i = 0; i < api.FPDFPage_GetAnnotCount(page); i++) {
        const annot = api.FPDFPage_GetAnnot(page, i); check(annot, 'Read annotation');
        try {
          const r = alloc(16), color = alloc(16);
          check(api.FPDFAnnot_GetRect(annot, r), 'Annotation rectangle');
          const hasColor = api.FPDFAnnot_GetColor(annot, 0, color, color+4, color+8, color+12);
          const quads = [], ink = [];
          for (let q = 0; q < api.FPDFAnnot_CountAttachmentPoints(annot); q++) {
            const p = alloc(32);
            if (api.FPDFAnnot_GetAttachmentPoints(annot, q, p)) {
              const v = Array.from(f32(p, 8)); quads.push([[v[0],v[1]],[v[2],v[3]],[v[4],v[5]],[v[6],v[7]]]);
            }
          }
          for (let s = 0; s < api.FPDFAnnot_GetInkListCount(annot); s++) {
            const count = api.FPDFAnnot_GetInkListPath(annot, s, 0, 0), p = alloc(count * 8);
            api.FPDFAnnot_GetInkListPath(annot, s, p, count);
            const v = Array.from(f32(p, count * 2)); ink.push(Array.from({length:count}, (_,i)=>[v[i*2],v[i*2+1]]));
          }
          let uri = null;
          const link = api.FPDFAnnot_GetLink(annot);
          if (link) {
            const action = api.FPDFLink_GetAction(link);
            if (action && api.FPDFAction_GetType(action) === 3) {
              const size = api.FPDFAction_GetURIPath(sourceDoc, action, 0, 0), p = alloc(size);
              api.FPDFAction_GetURIPath(sourceDoc, action, p, size);
              uri = new TextDecoder().decode(new Uint8Array(Pdfium.memory.buffer, p, Math.max(0,size-1)));
            }
          }
          result.push({index:i, subtype:api.FPDFAnnot_GetSubtype(annot), rect:Array.from(f32(r,4)),
            color:hasColor?Array.from(u32(color,4)):[255,255,0,255], flags:api.FPDFAnnot_GetFlags(annot),
            colorAvailable:!!hasColor,hasAppearance:api.FPDFAnnot_GetAP(annot,0,0,0)>0,
            quads, ink, id:string(annot,'NM'), title:string(annot,'T'), content:string(annot,'Contents'),
            subject:string(annot,'Subj'), modified:string(annot,'M'), created:string(annot,'CreationDate'),
            replyTo:linkedId(annot,'IRT'), popupId:linkedId(annot,'Popup'), uri});
        } finally { api.FPDFPage_CloseAnnot(annot); }
      }
      return result;
    }
    function transform(obj, m) {
      if (!Array.isArray(m) || m.length !== 6 || m.some(v=>!Number.isFinite(v))) throw new Error('Invalid PDF transform');
      api.FPDFPageObj_Transform(obj, ...m);
    }
    function paint(obj, m) {
      if (m.fill) check(api.FPDFPageObj_SetFillColor(obj, ...m.fill), 'Fill color');
      if (m.stroke) {
        check(api.FPDFPageObj_SetStrokeColor(obj, ...m.stroke), 'Stroke color');
        check(api.FPDFPageObj_SetStrokeWidth(obj, m.strokeWidth ?? 1), 'Stroke width');
        api.FPDFPageObj_SetLineCap(obj,m.lineCap ?? 1); api.FPDFPageObj_SetLineJoin(obj,m.lineJoin ?? 1);
        if (m.dashes?.length) {
          const p = alloc(m.dashes.length * 4); f32(p,m.dashes.length).set(m.dashes);
          check(api.FPDFPageObj_SetDashArray(obj,p,m.dashes.length,0),'Dash array');
        }
      }
      api.FPDFPageObj_SetBlendMode(obj,utf8(m.blendMode ?? 'Normal'));
    }
    function insert(page, obj) {
      if (!api.FPDFPage_InsertObject(page,obj)) throw new Error('Insert PDF object failed');
    }
    function insertForm(page,xobject,matrix) {
      const obj=api.FPDF_NewFormObjectFromXObject(xobject);check(obj,'Create PDF form');
      let pageOwnsObject=false;
      try {transform(obj,matrix);insert(page,obj);pageOwnsObject=true;}
      finally {if(!pageOwnsObject)api.FPDFPageObj_Destroy(obj);}
    }
    function objectAt(page,index) {
      if (!Number.isInteger(index) || index < 0 || index >= api.FPDFPage_CountObjects(page)) throw new Error('Invalid PDF object index');
      return api.FPDFPage_GetObject(page,index);
    }
    function writeAnnotation(page,m,index=null,preserveAppearance=false) {
      if (!supportedAnnotations.has(m.subtype)) throw new Error(`Unsupported annotation subtype ${m.subtype}`);
      if (index !== null && (index < 0 || index >= api.FPDFPage_GetAnnotCount(page))) throw new Error('Invalid annotation index');
      const annot = index===null?api.FPDFPage_CreateAnnot(page,m.subtype):api.FPDFPage_GetAnnot(page,index);
      check(annot,'Create/open annotation');
      try {
        if (api.FPDFAnnot_GetSubtype(annot)!==m.subtype) throw new Error('Annotation subtype cannot change');
        const quads = m.quads ?? [];
        if (index!==null && api.FPDFAnnot_CountAttachmentPoints(annot)!==quads.length) throw new Error('Replace annotation to change quad count');
        if (m.subtype===2 && !m.uri) throw new Error('Only URI link annotations can be written');
        const r = alloc(16); f32(r,4).set(m.rect); check(api.FPDFAnnot_SetRect(annot,r),'Annotation rectangle');
        if(!preserveAppearance) {
          api.FPDFAnnot_SetAP(annot,0,0);
          check(api.FPDFAnnot_SetColor(annot,0,...m.color),'Annotation color');
        }
        check(api.FPDFAnnot_SetFlags(annot,m.flags ?? 4),'Annotation flags');
        for (const [key,field] of [['NM','id'],['T','title'],['Contents','content'],['Subj','subject'],['M','modified']]) {
          if (m[field] != null) check(api.FPDFAnnot_SetStringValue(annot,utf8(key),utf16(m[field])),`Annotation ${key}`);
        }
        if (index===null && (m.created ?? m.modified)) {
          api.FPDFAnnot_SetStringValue(annot,utf8('CreationDate'),utf16(m.created ?? m.modified));
        }
        quads.forEach((q,i)=>{
          const p = alloc(32); f32(p,8).set(q.flat());
          check(index===null?api.FPDFAnnot_AppendAttachmentPoints(annot,p):api.FPDFAnnot_SetAttachmentPoints(annot,i,p),'Highlight quad');
        });
        if (m.subtype===15) {
          if (index!==null) api.FPDFAnnot_RemoveInkList(annot);
          for (const points of m.ink ?? []) {
            const p = alloc(points.length*8); f32(p,points.length*2).set(points.flat());
            check(api.FPDFAnnot_AddInkStroke(annot,p,points.length)>=0,'Ink stroke');
          }
        }
        if (m.subtype===2) {
          if (!m.uri) throw new Error('Only URI link annotations can be written');
          check(api.FPDFAnnot_SetURI(annot,utf8(m.uri)),'Link URI');
        }
        if(m.blankAppearance)check(api.FPDFAnnot_SetAP(annot,0,utf16('')),'Preserve annotation appearance layer');
      } catch (e) {
        if (index===null) api.FPDFPage_RemoveAnnot(page,api.FPDFPage_GetAnnotIndex(page,annot));
        throw e;
      } finally { api.FPDFPage_CloseAnnot(annot); }
    }
    function place(page,m) {
      const data = m.data instanceof Uint8Array?m.data:new Uint8Array(m.data);
      const buffer = bytes(data), source = api.FPDF_LoadMemDocument(buffer,data.length,m.password?utf8(m.password):0);
      check(source,'Open source PDF');
      let sourcePage=0;
      try {
        if (m.pageIndex<0 || m.pageIndex>=api.FPDF_GetPageCount(source)) throw new Error('Invalid source page index');
        sourcePage=api.FPDF_LoadPage(source,m.pageIndex); check(sourcePage,'Load source page');
        const g=geometry(sourcePage), matrix=multiply(m.matrix,rawToTopLeft(g));
        const height=g.rotation%2?g.rect[2]-g.rect[0]:g.rect[1]-g.rect[3];
        const formMatrix=multiply(m.matrix,[1,0,0,-1,0,height]);
        const copied=m.copyAnnotations?annotations(sourcePage,source):[];
        for (const a of copied) {
          if (a.subtype===16) continue;
          if (!supportedAnnotations.has(a.subtype) || (a.subtype===2 && !a.uri) || a.replyTo) {
            throw new Error(`Cannot preserve annotation subtype ${a.subtype} on a placed PDF page`);
          }
        }
        const xobject=api.FPDF_NewXObjectFromPage(doc,source,m.pageIndex); check(xobject,'Import PDF page');
        try {
          insertForm(page,xobject,formMatrix);
        } finally { api.FPDF_CloseXObject(xobject); }
        const preserveAppearance=copied.some(a=>a.hasAppearance);
        if(preserveAppearance) {
          const appearanceDoc=api.FPDF_LoadMemDocument(buffer,data.length,m.password?utf8(m.password):0);
          check(appearanceDoc,'Open annotation appearance copy');
          const appearancePage=api.FPDF_LoadPage(appearanceDoc,m.pageIndex);
          try {
            check(appearancePage,'Load annotation appearance page');
            for(let i=api.FPDFPage_CountObjects(appearancePage)-1;i>=0;i--) {
              const obj=api.FPDFPage_GetObject(appearancePage,i);
              check(api.FPDFPage_RemoveObject(appearancePage,obj),'Isolate annotation appearance');api.FPDFPageObj_Destroy(obj);
            }
            check(api.FPDFPage_GenerateContent(appearancePage),'Generate appearance page');
            const bitmap=api.FPDFBitmap_Create(1,1,1);
            check(bitmap,'Create annotation appearance bitmap');
            try{api.FPDF_RenderPageBitmap(bitmap,appearancePage,0,0,1,1,0,1);}finally{api.FPDFBitmap_Destroy(bitmap);}
            const status=api.FPDFPage_Flatten(appearancePage,0);check(status,'Flatten annotation appearance copy');
            if(status===1) {
              const appearance=api.FPDF_NewXObjectFromPage(doc,appearanceDoc,m.pageIndex);check(appearance,'Import annotation appearance');
              try {
                insertForm(page,appearance,formMatrix);
              } finally{api.FPDF_CloseXObject(appearance);}
            }
          } finally{if(appearancePage)api.FPDF_ClosePage(appearancePage);api.FPDF_CloseDocument(appearanceDoc);}
        }
        for (const a of copied) {
          if (a.subtype===16) continue;
          writeAnnotation(page,{...a,rect:transformedRect(matrix,a.rect),
            blankAppearance:preserveAppearance,
            quads:a.quads.map(q=>q.map(p=>point(matrix,p))),ink:a.ink.map(s=>s.map(p=>point(matrix,p)))});
        }
      } finally { if(sourcePage)api.FPDF_ClosePage(sourcePage); api.FPDF_CloseDocument(source); }
    }
    function draw(page,m) {
      if (m.type==='page') { place(page,m); return; }
      if (m.type==='transformObject') { transform(objectAt(page,m.index),m.matrix); return; }
      if (m.type==='removeObject') {
        const obj=objectAt(page,m.index); check(api.FPDFPage_RemoveObject(page,obj),'Remove object');
        api.FPDFPageObj_Destroy(obj); return;
      }
      let obj=0,font=0;
      try {
        switch(m.type) {
          case 'path': {
            if(!m.commands.length)return;
            const start=m.commands[0]; if(start[0]!==0 || start.length!==3)throw new Error('Path must start with moveTo');
            obj=api.FPDFPageObj_CreateNewPath(start[1],start[2]); check(obj,'Create path');
            for(const c of m.commands.slice(1)) {
              let ok;
              switch(c[0]) {
                case 0:ok=api.FPDFPath_MoveTo(obj,c[1],c[2]);break;
                case 1:ok=api.FPDFPath_LineTo(obj,c[1],c[2]);break;
                case 2:ok=api.FPDFPath_BezierTo(obj,...c.slice(1));break;
                case 3:ok=api.FPDFPath_Close(obj);break;
                default:throw new Error('Unknown path command');
              }
              check(ok,'Path command');
            }
            paint(obj,m); check(api.FPDFPath_SetDrawMode(obj,m.fill?(m.evenOdd?1:2):0,m.stroke?1:0),'Path draw mode');break;
          }
          case 'image': {
            const data=m.data instanceof Uint8Array?m.data:new Uint8Array(m.data);
            if(m.width<=0 || m.height<=0 || data.length!==m.width*m.height*4)throw new Error('Invalid RGBA bitmap');
            const bgra=new Uint8Array(data.length);
            for(let i=0;i<data.length;i+=4) { bgra[i]=data[i+2];bgra[i+1]=data[i+1];bgra[i+2]=data[i];bgra[i+3]=data[i+3]; }
            const bitmap=api.FPDFBitmap_CreateEx(m.width,m.height,4,bytes(bgra),m.width*4);check(bitmap,'Create bitmap');
            try {obj=api.FPDFPageObj_NewImageObj(doc);check(obj,'Create image');check(api.FPDFImageObj_SetBitmap(0,0,obj,bitmap),'Set bitmap');}
            finally{api.FPDFBitmap_Destroy(bitmap);}break;
          }
          case 'text': {
            const key=m.fontKey ?? m.fontName;
            font=fonts.get(key);
            if(!font) {
              if(m.font) { const data=m.font instanceof Uint8Array?m.font:new Uint8Array(m.font);
                font=api.FPDFText_LoadFont(doc,bytes(data),data.length,2,1);
              } else font=api.FPDFText_LoadStandardFont(doc,utf8(m.fontName));
              check(font,'Load font');fonts.set(key,font);
            }
            check(font,'Load font'); obj=api.FPDFPageObj_CreateTextObj(doc,font,m.fontSize);check(obj,'Create text');
            check(api.FPDFText_SetText(obj,utf16(m.text)),'Set text');paint(obj,m);
            if(m.stroke)check(api.FPDFTextObj_SetTextRenderMode(obj,2),'Text render mode');break;
          }
          default:throw new Error(`Unsupported PDF object ${m.type}`);
        }
        transform(obj,m.matrix);insert(page,obj);obj=0;
      } finally {if(obj)api.FPDFPageObj_Destroy(obj);}
    }
    let page=0;
    try {
      if(request.action==='capabilities') {
        for(const name of ['FPDF_NewXObjectFromPage','FPDF_NewFormObjectFromXObject','FPDFPage_InsertObject',
          'FPDFPage_GetAnnotCount','FPDFAnnot_GetStringValue','FPDFPage_CreateAnnot','FPDFAnnot_SetURI','FPDFPage_Flatten']) {
          if(typeof api[name]!=='function')throw new Error(`Incompatible PDFium WASM: missing ${name}`);
        }
        return {protocol:1};
      }
      if(request.action==='handles')return Object.keys(disposers).map(Number);
      if(!Object.hasOwn(disposers,doc))throw new Error('PDF document is disposed');
      if(request.action==='addPage') {
        page=api.FPDFPage_New(doc,api.FPDF_GetPageCount(doc),request.width,request.height);check(page,'Create page');
        check(api.FPDFPage_GenerateContent(page),'Generate page');return {};
      }
      if(request.pageIndex<0 || request.pageIndex>=api.FPDF_GetPageCount(doc))throw new Error('Invalid PDF page index');
      page=api.FPDF_LoadPage(doc,request.pageIndex);check(page,'Load page');
      switch(request.action) {
        case 'geometry':return geometry(page);
        case 'annotations':return annotations(page);
        case 'listObjects':return Array.from({length:api.FPDFPage_CountObjects(page)},(_,i)=>{
          const obj=api.FPDFPage_GetObject(page,i),r=alloc(16),m=alloc(24);
          check(api.FPDFPageObj_GetBounds(obj,r,r+4,r+8,r+12),'Object bounds');check(api.FPDFPageObj_GetMatrix(obj,m),'Object matrix');
          const v=Array.from(f32(r,4));return {index:i,type:api.FPDFPageObj_GetType(obj),rect:[v[0],v[3],v[2],v[1]],matrix:Array.from(f32(m,6))};
        });
        case 'objects':
          try { for(const m of request.commands)draw(page,m); }
          finally { check(api.FPDFPage_GenerateContent(page),'Generate content'); }
          return {};
        case 'annotation':writeAnnotation(page,request.spec,request.index ?? null,request.preserveAppearance ?? false);return {};
        case 'removeAnnotation':check(api.FPDFPage_RemoveAnnot(page,request.index),'Remove annotation');return {};
        default:throw new Error(`Unknown pdfrx_plus action ${request.action}`);
      }
    } finally {if(page)api.FPDF_ClosePage(page);for(const font of fonts.values())api.FPDFFont_Close(font);for(const p of pointers.reverse())api.free(p);}
  };
})();
