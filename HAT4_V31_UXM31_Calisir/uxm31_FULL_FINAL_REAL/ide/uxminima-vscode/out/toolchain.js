"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.UxmToolchain = void 0;
const vscode = __importStar(require("vscode"));
const path = __importStar(require("path"));
const fs = __importStar(require("fs"));
const child_process_1 = require("child_process");
class UxmToolchain {
    constructor(output) {
        this.output = output;
    }
    getPaths() {
        const cfg = vscode.workspace.getConfiguration("uxminima");
        const root = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath ?? process.cwd();
        const buildDirSetting = cfg.get("buildDirectory", "build");
        return {
            fullTool: this.resolveTool(cfg.get("fullToolPath", "uxm31_full_tool.exe"), root),
            compiler: this.resolveTool(cfg.get("compilerPath", "uxm31_compiler_full.exe"), root),
            runtime: this.resolveTool(cfg.get("runtimePath", "uxm31_runtime_fb_full.bas"), root),
            nasm: cfg.get("nasmPath", "nasm"),
            fbc: cfg.get("fbcPath", "fbc"),
            buildDir: path.isAbsolute(buildDirSetting) ? buildDirSetting : path.join(root, buildDirSetting)
        };
    }
    artifactsFor(sourceFile) {
        const paths = this.getPaths();
        const baseName = path.basename(sourceFile, path.extname(sourceFile));
        if (!fs.existsSync(paths.buildDir)) {
            fs.mkdirSync(paths.buildDir, { recursive: true });
        }
        return {
            source: sourceFile,
            baseName,
            buildDir: paths.buildDir,
            asm: path.join(paths.buildDir, `${baseName}.asm`),
            obj: path.join(paths.buildDir, `${baseName}.o`),
            exe: path.join(paths.buildDir, `${baseName}.exe`),
            trace: path.join(paths.buildDir, `${baseName}.trace.ndjson`),
            uir: path.join(paths.buildDir, `${baseName}.uir.json`),
            opt: path.join(paths.buildDir, `${baseName}.opt.json`)
        };
    }
    async runTrace(sourceFile) {
        const paths = this.getPaths();
        const art = this.artifactsFor(sourceFile);
        await this.run(paths.fullTool, ["run", art.source, art.trace], "Run Trace");
        return art;
    }
    async exportUIR(sourceFile) {
        const paths = this.getPaths();
        const art = this.artifactsFor(sourceFile);
        await this.run(paths.fullTool, ["uir", art.source, art.uir], "Export UIR");
        return art;
    }
    async exportOPT(sourceFile) {
        const paths = this.getPaths();
        const art = this.artifactsFor(sourceFile);
        await this.run(paths.fullTool, ["opt", art.source, art.opt], "Export OPT");
        return art;
    }
    async buildNative(sourceFile) {
        const paths = this.getPaths();
        const art = this.artifactsFor(sourceFile);
        await this.run(paths.compiler, [art.source, art.asm], "UXM -> ASM");
        await this.run(paths.nasm, ["-f", "win64", art.asm, "-o", art.obj], "ASM -> OBJ");
        await this.run(paths.fbc, ["-x", art.exe, paths.runtime, art.obj], "Runtime + OBJ -> EXE");
        return art;
    }
    resolveTool(toolPath, root) {
        if (path.isAbsolute(toolPath)) {
            return toolPath;
        }
        const fromRoot = path.join(root, toolPath);
        if (fs.existsSync(fromRoot)) {
            return fromRoot;
        }
        const fromTools = path.join(root, "tools", toolPath);
        if (fs.existsSync(fromTools)) {
            return fromTools;
        }
        return toolPath;
    }
    run(command, args, title) {
        this.output.appendLine(`\n[${title}] ${command} ${args.map(a => JSON.stringify(a)).join(" ")}`);
        return new Promise((resolve, reject) => {
            (0, child_process_1.execFile)(command, args, { cwd: vscode.workspace.workspaceFolders?.[0]?.uri.fsPath }, (error, stdout, stderr) => {
                if (stdout) {
                    this.output.appendLine(stdout);
                }
                if (stderr) {
                    this.output.appendLine(stderr);
                }
                if (error) {
                    this.output.show(true);
                    reject(new Error(`${title} başarısız: ${error.message}`));
                    return;
                }
                resolve();
            });
        });
    }
}
exports.UxmToolchain = UxmToolchain;
//# sourceMappingURL=toolchain.js.map