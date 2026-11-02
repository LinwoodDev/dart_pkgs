// Runs the actual pdfrx PDFium WASM and addon protocol, without a mocked PDFium.
// node test/web_worker_test.mjs /path/to/pdfrx/assets
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import vm from 'node:vm';
import {fileURLToPath} from 'node:url';

const assets = process.argv[2];
if (!assets) throw new Error('Usage: node test/web_worker_test.mjs /path/to/pdfrx/assets');
const wasm = await fs.readFile(`${assets}/pdfium.wasm`);
const url='https://pdfrx-test.invalid/pdfium.wasm';
globalThis.fetch=async request=>{
  assert.equal(String(request),url);
  return new Response(wasm,{headers:{'Content-Type':'application/wasm'}});
};
globalThis.self=globalThis;
globalThis.location={href:url};
globalThis.postMessage=()=>{};
const base=await fs.readFile(`${assets}/pdfium_worker.js`,'utf8');
const addon=await fs.readFile(fileURLToPath(new URL('../assets/pdfrx_plus_worker.js',import.meta.url)),'utf8');
vm.runInThisContext(`const pdfiumWasmUrl=${JSON.stringify(url)};\n${base}\n${addon}\n`+
  'globalThis.testPdfium={init:initializePdfium,functions,api:()=>Pdfium.wasmExports,memory:()=>Pdfium.memory};');
const h=globalThis.testPdfium;
const call=(handle,action,extra={})=>h.functions.pdfrxPlusDispatch({handle,action,...extra});
const identity=[1,0,0,1,0,0];
const rectangle={type:'path',commands:[[0,10,20],[1,30,20],[1,30,30],[1,10,30],[3]],
  fill:[255,0,0,255],stroke:null,matrix:identity,blendMode:'Normal'};
let source,target,restored;
try {
  await h.init();
  assert.equal(call(0,'capabilities').protocol,1);
  source=h.functions.createNewDocument();
  call(source.docHandle,'addPage',{width:100,height:80});
  call(source.docHandle,'objects',{pageIndex:0,commands:[rectangle,
    {type:'text',text:'searchable',fontName:'Helvetica',fontSize:10,fill:[0,0,0,255],matrix:[1,0,0,1,10,50]}]});
  call(source.docHandle,'annotation',{pageIndex:0,spec:{subtype:1,rect:[50,60,65,45],id:'source-note',
    content:'Grüße 🦋',title:'Author',subject:'',flags:4,color:[255,255,0,255],quads:[],ink:[]}});
  call(source.docHandle,'annotation',{pageIndex:0,spec:{subtype:9,rect:[10,60,45,45],id:'highlight',
    content:'highlight',title:'',subject:'',flags:4,color:[255,255,0,255],
    quads:[[[10,60],[45,60],[10,45],[45,45]]],ink:[]}});
  const annotations=call(source.docHandle,'annotations',{pageIndex:0});
  assert.equal(annotations[0].content,'Grüße 🦋');
  assert.equal(annotations[1].quads.length,1);
  const encoded=h.functions.encodePdf({docHandle:source.docHandle});
  const data=encoded.result?.data ?? encoded.data;
  assert.ok(data.byteLength>100);
  restored=h.functions.loadDocumentFromData({data});
  assert.equal(call(restored.docHandle,'annotations',{pageIndex:0})[0].content,'Grüße 🦋');
  target=h.functions.createNewDocument();
  call(target.docHandle,'addPage',{width:200,height:200});
  call(target.docHandle,'objects',{pageIndex:0,commands:[{type:'page',data:new Uint8Array(data),
    pageIndex:0,matrix:[1,0,0,-1,30,150],copyAnnotations:true}]});
  assert.equal(call(target.docHandle,'listObjects',{pageIndex:0})[0].type,5);
  assert.equal(call(target.docHandle,'annotations',{pageIndex:0})[0].rect[0],80);
  call(target.docHandle,'removeAnnotation',{pageIndex:0,index:0});
  assert.equal(call(target.docHandle,'annotations',{pageIndex:0}).length,1);
  const api=h.api();
  const page=api.FPDF_LoadPage(source.docHandle,0);
  api.FPDFPage_SetCropBox(page,5,10,95,70);api.FPDFPage_SetRotation(page,1);api.FPDF_ClosePage(page);
  const rotated=h.functions.encodePdf({docHandle:source.docHandle});
  call(target.docHandle,'addPage',{width:200,height:200});
  call(target.docHandle,'objects',{pageIndex:1,commands:[{type:'page',data:new Uint8Array(rotated.result?.data ?? rotated.data),
    pageIndex:0,matrix:[1,0,0,-1,30,150],copyAnnotations:false}]});
  const obj=call(target.docHandle,'listObjects',{pageIndex:1})[0];
  assert.equal(obj.rect[0],40);assert.equal(obj.rect[1],145);
  const targetPage=api.FPDF_LoadPage(target.docHandle,1), bitmap=api.FPDFBitmap_Create(200,200,1);
  try {
    api.FPDFBitmap_FillRect(bitmap,0,0,200,200,0xffffffff);
    api.FPDF_RenderPageBitmap(bitmap,targetPage,0,0,200,200,0,0);
    const stride=api.FPDFBitmap_GetStride(bitmap), buffer=api.FPDFBitmap_GetBuffer(bitmap);
    const pixels=new Uint8Array(h.memory().buffer,buffer,stride*200), at=65*stride+45*4;
    assert.ok(pixels[at+2]>240);assert.ok(pixels[at+1]<20);
  } finally {api.FPDFBitmap_Destroy(bitmap);api.FPDF_ClosePage(targetPage);}
  console.log('WASM integration passed: paths, text, Unicode comments, highlights, save/reopen, page offset, CropBox/rotation, deletion.');
} finally {
  for(const doc of [source,target,restored])if(doc)h.functions.closeDocument(doc);
}
