using System;
using System.IO;
using System.IO.Compression;
using System.Reflection;
using System.Security.Cryptography;
using System.Diagnostics;
using System.ComponentModel;
using System.Drawing;
using System.Text;
using System.Windows.Forms;
[assembly: AssemblyTitle("Agents Bar Setup")]
[assembly: AssemblyVersion("0.9.9.0")]
[assembly: AssemblyFileVersion("0.9.9.0")]
internal static class Setup {
    private const string PayloadHash = "PAYLOAD_SHA256";
    public const string Version = "0.9.9";
    static Stream Payload() { return Assembly.GetExecutingAssembly().GetManifestResourceStream("AgentsBar.Payload.zip"); }
    public static void Verify() {
        using (Stream stream = Payload()) using (SHA256 hash = SHA256.Create()) {
            string actual = BitConverter.ToString(hash.ComputeHash(stream)).Replace("-", "").ToLowerInvariant();
            if (actual != PayloadHash) throw new InvalidDataException("O pacote do instalador está danificado.");
        }
    }
    public static string Extract(string destination) {
        Verify();
        string root = Path.GetFullPath(destination).TrimEnd(Path.DirectorySeparatorChar);
        if (Directory.Exists(root) || File.Exists(root)) throw new IOException("A pasta temporária já existe.");
        Directory.CreateDirectory(root);
        string prefix = root + Path.DirectorySeparatorChar;
        using (Stream stream = Payload()) using (ZipArchive archive = new ZipArchive(stream, ZipArchiveMode.Read)) {
            if (archive.Entries.Count > 10000) throw new InvalidDataException("Pacote fora do limite.");
            long total = 0;
            foreach (ZipArchiveEntry entry in archive.Entries) {
                total += entry.Length;
                if (total > 1073741824L || entry.Length > 536870912L) throw new InvalidDataException("Pacote fora do limite.");
                string file = Path.GetFullPath(Path.Combine(root, entry.FullName));
                if (!file.StartsWith(prefix, StringComparison.OrdinalIgnoreCase)) throw new InvalidDataException("Caminho inválido no pacote.");
                if (entry.FullName.EndsWith("/")) { Directory.CreateDirectory(file); continue; }
                Directory.CreateDirectory(Path.GetDirectoryName(file));
                using (Stream input = entry.Open()) using (FileStream output = new FileStream(file, FileMode.CreateNew)) input.CopyTo(output);
            }
        }
        string package = Path.Combine(root, "AgentsBar-" + Version + "-win64");
        if (!File.Exists(Path.Combine(package, "manifest.json"))) throw new InvalidDataException("Manifesto não encontrado.");
        return package;
    }
    public static void CleanOwnedTemp(string path) {
        string root = Path.GetFullPath(path);
        string temp = Path.GetFullPath(Path.GetTempPath()).TrimEnd(Path.DirectorySeparatorChar) + Path.DirectorySeparatorChar;
        if (!root.StartsWith(temp, StringComparison.OrdinalIgnoreCase) || !Path.GetFileName(root).StartsWith("AgentsBarSetup-", StringComparison.Ordinal)) return;
        // Only the exact GUID folder created by this installer is removed.
        if (Directory.Exists(root)) Directory.Delete(root, true);
    }
    public static string Install(string target, bool shortcut) {
        string temp = Path.Combine(Path.GetTempPath(), "AgentsBarSetup-" + Guid.NewGuid().ToString("N"));
        try {
            string package = Extract(temp);
            ProcessStartInfo info = new ProcessStartInfo(Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System), @"WindowsPowerShell\v1.0\powershell.exe"));
            info.Arguments = "-NoProfile -NonInteractive -ExecutionPolicy Bypass -File \"" + Path.Combine(package,"install.ps1") + "\" -PackageRoot \"" + package + "\" -InstallRoot \"" + target + "\"" + (shortcut ? "" : " -NoShortcut");
            info.UseShellExecute = false; info.CreateNoWindow = true; info.WindowStyle = ProcessWindowStyle.Hidden;
            info.RedirectStandardOutput = true; info.RedirectStandardError = true;
            StringBuilder output = new StringBuilder();
            using (Process process = new Process()) {
                process.StartInfo = info;
                process.OutputDataReceived += delegate(object sender, DataReceivedEventArgs e) { if(e.Data != null) lock(output) output.AppendLine(e.Data); };
                process.ErrorDataReceived += delegate(object sender, DataReceivedEventArgs e) { if(e.Data != null) lock(output) output.AppendLine(e.Data); };
                process.Start(); process.BeginOutputReadLine(); process.BeginErrorReadLine(); process.WaitForExit();
                if (process.ExitCode != 0) throw new IOException(output.ToString());
            }
            return target;
        } finally { try { CleanOwnedTemp(temp); } catch { /* Safe leftovers can be removed by Windows temporary-file cleanup. */ } }
    }
    [STAThread]
    public static int Main(string[] args) {
        // These explicit CLI modes do not construct a Form or initialize a GUI.
        try {
            if (args.Length == 1 && args[0] == "--verify-payload") { Verify(); Console.WriteLine("Payload verified: " + Version); return 0; }
            if (args.Length == 2 && args[0] == "--extract-only") { Console.WriteLine(Extract(args[1])); return 0; }
            if (args.Length != 0) return 2;
            Application.EnableVisualStyles(); Application.SetCompatibleTextRenderingDefault(false); Application.Run(new SetupForm()); return 0;
        } catch (Exception error) {
            if (args.Length != 0) { Console.Error.WriteLine(error.Message); return 1; }
            MessageBox.Show(error.Message,"Agents Bar",MessageBoxButtons.OK,MessageBoxIcon.Error);return 1;
        }
    }
}
internal sealed class SetupForm : Form {
    readonly TextBox target = new TextBox();
    readonly CheckBox shortcut = new CheckBox();
    readonly Button install = new Button();
    readonly Button cancel = new Button();
    readonly Button browse = new Button();
    readonly Label status = new Label();
    readonly ProgressBar progress = new ProgressBar();
    bool working;
    public SetupForm() {
        Text = "Agents Bar · Instalação " + Setup.Version; ClientSize = new Size(610,405);
        FormBorderStyle = FormBorderStyle.FixedDialog; MaximizeBox = false; StartPosition = FormStartPosition.CenterScreen;
        BackColor = Color.FromArgb(21,28,41); ForeColor = Color.FromArgb(238,229,213); Font = new Font("Segoe UI",10);
        Label title = new Label { Text="AGENTS BAR",Location=new Point(28,24),Size=new Size(550,38),Font=new Font("Segoe UI",22,FontStyle.Bold),ForeColor=Color.FromArgb(221,186,119) }; Controls.Add(title);
        Label description = new Label { Text="Instalar ou atualizar · 0.9.9\nO jogo e seus dados ficam neste computador. Feche o Agents Bar antes de continuar.",Location=new Point(30,76),Size=new Size(550,56) };Controls.Add(description);
        Label folder = new Label { Text="Pasta de instalação",Location=new Point(30,148),Size=new Size(280,24) };Controls.Add(folder);
        target.Location=new Point(30,176);target.Size=new Size(448,28);target.Text=Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),@"Programs\Agents Bar");Controls.Add(target);
        browse.Text="Alterar";browse.Location=new Point(488,174);browse.Size=new Size(90,30);browse.Click+=delegate {using(FolderBrowserDialog dialog=new FolderBrowserDialog()){dialog.Description="Escolha uma pasta exclusiva para Agents Bar";if(dialog.ShowDialog(this)==DialogResult.OK)target.Text=Path.Combine(dialog.SelectedPath,"Agents Bar");}};Controls.Add(browse);
        shortcut.Text="Criar um atalho Agents Bar na Área de Trabalho";shortcut.Checked=true;shortcut.Location=new Point(30,220);shortcut.Size=new Size(550,28);Controls.Add(shortcut);
        status.Text="Sem conexão automática com agentes. O Pro ainda não está publicado.";status.Location=new Point(30,260);status.Size=new Size(550,42);Controls.Add(status);
        progress.Location=new Point(30,311);progress.Size=new Size(550,8);progress.Style=ProgressBarStyle.Marquee;progress.Visible=false;Controls.Add(progress);
        cancel.Text="Cancelar";cancel.Location=new Point(330,346);cancel.Size=new Size(110,34);cancel.Click+=delegate {Close();};Controls.Add(cancel);
        install.Text="Instalar / atualizar";install.Location=new Point(450,346);install.Size=new Size(130,34);install.Click+=StartInstall;Controls.Add(install);
        FormClosing+=delegate(object sender,FormClosingEventArgs e){if(working)e.Cancel=true;};
    }
    void StartInstall(object sender,EventArgs args) {
        string path;
        try {
            path=Path.GetFullPath(target.Text.Trim());
            if (!Path.IsPathRooted(target.Text.Trim()) || path.Contains("\"") || path.TrimEnd('\\')==Path.GetPathRoot(path).TrimEnd('\\')) throw new ArgumentException();
        } catch {status.Text="Escolha uma pasta exclusiva usando um caminho completo.";return;}
        bool makeShortcut=shortcut.Checked;
        working=true;target.Enabled=false;browse.Enabled=false;shortcut.Enabled=false;install.Enabled=false;cancel.Enabled=false;progress.Visible=true;
        status.Text="Conferindo os arquivos e preparando a instalação…";
        BackgroundWorker worker=new BackgroundWorker();
        worker.DoWork+=delegate(object o,DoWorkEventArgs e){e.Result=Setup.Install(path,makeShortcut);};
        worker.RunWorkerCompleted+=delegate(object o,RunWorkerCompletedEventArgs e){
            working=false;progress.Visible=false;cancel.Enabled=true;
            if(e.Error!=null){status.Text="Não foi possível concluir. Seus dados foram preservados.";target.Enabled=true;browse.Enabled=true;shortcut.Enabled=true;install.Enabled=true;MessageBox.Show(this,e.Error.Message,"Instalação não concluída",MessageBoxButtons.OK,MessageBoxIcon.Warning);}
            else {status.Text="Pronto. Abra Agents Bar pelo atalho ou pela pasta escolhida.";cancel.Text="Concluir";}
            worker.Dispose();
        };
        worker.RunWorkerAsync();
    }
}
