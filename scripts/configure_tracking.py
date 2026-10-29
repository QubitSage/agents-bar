"""Generate reviewable hook snippets. Never edits another tool's configuration or discovers sessions."""
import json
import os
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]


def windows_hook(target,python,hook,directory,provider,event=None):
    def quote(path):return "'"+str(path).replace("'","''")+"'"
    script=target/(provider+('-'+event if event else '')+'-observer.ps1')
    code="# Generated observer. Reads only the JSON explicitly supplied on stdin.\n[Console]::InputEncoding=[Text.UTF8Encoding]::new()\n$OutputEncoding=[Text.UTF8Encoding]::new()\n$env:PYTHONIOENCODING='utf-8'\n$data=[Console]::In.ReadToEnd()\n$data | & "+quote(python)+' '+quote(hook)+' --provider '+provider+' --directory '+quote(directory)+((' --hook '+event) if event else '')+'\n'
    script.write_text(code,encoding='utf-8-sig')
    return 'powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File "'+script.as_posix()+'"'


def main():
    target=ROOT/'integrations';target.mkdir(exist_ok=True)
    python=ROOT/'tools/python/python.exe';hook=ROOT/'bridge/hook.py';directory=Path(os.environ['AGENTS_BAR_DATA'])/'tracking' if os.environ.get('AGENTS_BAR_DATA') else ROOT/'runtime/tracking'
    def command(provider,event=None):
        return windows_hook(target,python,hook,directory,provider,event)
    claude={name:[{'hooks':[{'type':'command','command':command('claude'),'timeout':2}]}] for name in ['SessionStart','UserPromptSubmit','PreToolUse','PostToolUse','PermissionRequest','Notification','PostToolUseFailure','SubagentStart','SubagentStop','Stop','SessionEnd']}
    codex={name:[{'hooks':[{'type':'command','command':command('codex'),'timeout':2}]}] for name in ['SessionStart','UserPromptSubmit','PreToolUse','PostToolUse','PermissionRequest','SubagentStart','SubagentStop','Stop','Interrupt','SessionEnd']}
    cursor={name:[{'command':command('cursor')}] for name in ['sessionStart','beforeSubmitPrompt','preToolUse','postToolUse','subagentStart','subagentStop','stop','sessionEnd']}
    antigravity={name:[{'hooks':[{'type':'command','command':command('antigravity',name)}]}] for name in ['PostToolUse']}
    antigravity['SessionStart']=[{'type':'command','command':command('antigravity','SessionStart')}]
    antigravity['PostInvocation']=[{'type':'command','command':command('antigravity','PostInvocation')}]
    antigravity['Stop']=[{'type':'command','command':command('antigravity','Stop')}]
    documents={'claude.settings.snippet.json':{'hooks':claude},'claude.statusline.snippet.json':{'statusLine':{'type':'command','command':command('claude','statusline')}},
      'codex.hooks.snippet.json':{'hooks':codex},
      'cursor.hooks.snippet.json':{'version':1,'hooks':cursor},'antigravity.hooks.snippet.json':{'agents-bar':antigravity},
      'mcp.snippet.json':{'mcpServers':{'agents-bar':{'command':str(python),'args':[str(ROOT/'bridge/mcp_server.py'),'--directory',str(directory)]}}}}
    for name,data in documents.items():(target/name).write_text(json.dumps(data,indent=2),encoding='utf-8')
    print(f'{len(documents)} snippets generated in {target}. Review and merge explicitly.')


if __name__=='__main__':main()
