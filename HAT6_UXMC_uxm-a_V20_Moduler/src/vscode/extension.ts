import * as vscode from 'vscode';

const serviceFamilies: Array<[number, number, string]> = [
  [0, 19, 'core'], [20, 39, 'arithmetic'], [40, 59, 'math'], [60, 79, 'io'],
  [80, 89, 'pointer/memory'], [90, 127, 'fifo/data/sort/mode'], [130, 159, 'flags/compare/endian'],
  [160, 199, 'matrix'], [200, 239, 'floating point'], [260, 299, 'statistics/numeric'],
  [300, 319, 'string'], [340, 379, 'string extended'], [400, 419, 'file'],
  [420, 459, 'numeric/complex'], [480, 511, 'bio'], [512, 599, 'tensor'],
  [600, 679, 'sparse vector'], [700, 759, 'ml data'], [760, 769, 'hypothesis'],
  [790, 795, 'posthoc'], [810, 823, 'ai metrics']
];

function familyOf(id: number): string {
  for (const [a, b, name] of serviceFamilies) if (id >= a && id <= b) return name;
  return 'invalid';
}

export function activate(context: vscode.ExtensionContext) {
  context.subscriptions.push(vscode.languages.registerHoverProvider('uxm', {
    provideHover(document, position) {
      const range = document.getWordRangeAtPosition(position, /@[#@*]?[0-9]+/);
      if (!range) return undefined;
      const text = document.getText(range);
      const id = Number(text.replace(/[^0-9]/g, ''));
      return new vscode.Hover(`UXM service ${text}: ${familyOf(id)}`);
    }
  }));

  context.subscriptions.push(vscode.commands.registerCommand('uxm.showServiceFamily', () => {
    const editor = vscode.window.activeTextEditor;
    const text = editor?.document.getText(editor.selection) ?? '';
    const id = Number(text.replace(/[^0-9]/g, ''));
    vscode.window.showInformationMessage(`UXM @${id}: ${familyOf(id)}`);
  }));
}

export function deactivate() {}
