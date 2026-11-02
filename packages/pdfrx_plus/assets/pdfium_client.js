// Versioned addon for pdfrx 2.6.x. Reuses its worker/runtime assets unchanged.
const base = new URL(globalThis.pdfrxPlusBaseModulesUrl ?? '../pdfrx/assets/', document.baseURI);
const addon = new URL('./pdfrx_plus_worker.js', import.meta.url);
const bootstrap = `const pdfiumWasmUrl=${JSON.stringify(new URL('pdfium.wasm', base).href)};` +
  `importScripts(${JSON.stringify(new URL('pdfium_worker.js', base).href)});` +
  `importScripts(${JSON.stringify(addon.href)});`;
URL.revokeObjectURL(globalThis.pdfiumWasmWorkerUrl);
globalThis.pdfiumWasmWorkerUrl = URL.createObjectURL(new Blob([bootstrap], {type: 'application/javascript'}));
// HTMLScriptElement.load can fire before an asynchronously imported module has
// evaluated. pdfrx sends its init command immediately on that event, so expose
// a synchronous proxy while the original client module is loading. Its module
// replaces this proxy with the original communicator before the promise settles.
const clientReady = import(new URL('pdfium_client.js', base).href)
  .then(() => globalThis.PdfiumWasmCommunicator);
globalThis.PdfiumWasmCommunicator = {
  sendCommand(...args) {
    return clientReady.then(client => client.sendCommand(...args));
  }
};
