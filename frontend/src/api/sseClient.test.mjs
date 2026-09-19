import assert from 'node:assert/strict';
import { postSse } from './sseClient.ts';

let cleared = 0;
let expired;
globalThis.window = {
  setTimeout(fn) { expired = fn; return 1; },
  clearTimeout() { cleared++; },
};
globalThis.fetch = async () => { throw new TypeError('Failed to fetch'); };
await assert.rejects(postSse('/test', {}, () => {}), /无法连接服务/);
assert.equal(cleared, 1);

globalThis.fetch = (_url, { signal }) => new Promise((_resolve, reject) => {
  signal.addEventListener('abort', () => reject(new DOMException('abort', 'AbortError')));
  queueMicrotask(() => expired());
});
await assert.rejects(postSse('/test', {}, () => {}), /请求超时/);
assert.equal(cleared, 2);

let canceled = false;
const frames = ['data:{"type":"progress"}\r', '\n\r\ndata: {"type":"result","data":[]}\r\n\r\n'];
globalThis.fetch = async () => new Response(new ReadableStream({
  start(controller) { for (const frame of frames) controller.enqueue(new TextEncoder().encode(frame)); },
  cancel() { canceled = true; },
}));
const events = [];
await postSse('/test', {}, event => events.push(event));
assert.deepEqual(events.map(e => e.type), ['progress', 'result']);
assert.equal(canceled, true, 'terminal result must not wait for the server to close');

globalThis.fetch = async () => new Response('data: {"type":"progress"}\n\n');
await assert.rejects(postSse('/test', {}, () => {}), /提前结束/);
globalThis.fetch = async () => new Response('data: {"type":"error","message":"模型服务连接失败"}\n\n');
const failures = [];
await postSse('/test', {}, event => failures.push(event));
assert.equal(failures[0].type, 'error');
assert.equal(cleared, 5);
console.log('SSE regression: connection failure, timeout, CRLF, terminal cancellation, early EOF, error event passed');
