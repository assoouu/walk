import { create } from 'ipfs-http-client';

const ipfs = create('/ip4/127.0.0.1/tcp/5001');  // 로컬 IPFS 노드 주소

export default ipfs;
