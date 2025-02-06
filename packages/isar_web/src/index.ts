import { OPFSCoopSyncVFS } from 'wa-sqlite/src/examples/OPFSCoopSyncVFS.js';
import { AccessHandlePoolVFS } from 'wa-sqlite/src/examples/AccessHandlePoolVFS.js';
import isar, { registerCustomVfs } from '../wasm/isar.js';

enum VFS {
    OPFSCoopSync = 'opfsCoopSync',
    AccessHandlePool = 'accessHandlePool'
}

const initIsarWeb = async (wasm_url: string, vfsType?: VFS) => {
    const module = await isar(wasm_url);
    if (vfsType) {
        const vfs = vfsType === VFS.OPFSCoopSync ? OPFSCoopSyncVFS : AccessHandlePoolVFS;
        self['vfs'] = await vfs.create('isar', module);
        registerCustomVfs();
    }
    return module;
}

export { initIsarWeb };