const vscode = require('vscode');
function run(cmd){
  const term = vscode.window.createTerminal('UXM Türkçe');
  term.show();
  term.sendText(cmd);
}
function activate(context){
  const cmds = {
    'uxmTurkce.derle':'./derle.bat',
    'uxmTurkce.bellekTest':'./bellek.bat',
    'uxmTurkce.hizliTara':'./hizli.bat',
    'uxmTurkce.hataliTest':'./hata.bat -k -D',
    'uxmTurkce.tumTest':'./tum.bat -k',
    'uxmTurkce.rapor':'./rapor.bat'
  };
  for (const [name, cmd] of Object.entries(cmds)) {
    context.subscriptions.push(vscode.commands.registerCommand(name, () => run(cmd)));
  }
}
function deactivate(){}
module.exports={activate,deactivate};
