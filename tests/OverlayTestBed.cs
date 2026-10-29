using System;
using System.Drawing;
using System.IO;
using System.Windows.Forms;

class OverlayTestBed : Form {
    int clicks;
    TextBox input;
    Label status;
    string report;
    public OverlayTestBed(string file) {
        report=file;
        Text="Estacao Zero - Teste de clique e foco";
        BackColor=Color.FromArgb(16,30,39);
        ForeColor=Color.FromArgb(232,221,195);
        WindowState=FormWindowState.Maximized;
        var title=new Label {Text="ESTACAO ZERO / TESTE LOCAL",Dock=DockStyle.Top,Height=100,Font=new Font("Segoe UI",24),Padding=new Padding(32,28,0,0)};
        var hint=new Label {Text="Area de teste temporaria. Digite no campo; os controles do companion devem preservar o foco.",Dock=DockStyle.Top,Height=60,Font=new Font("Segoe UI",13),Padding=new Padding(32,8,0,0)};
        input=new TextBox {Dock=DockStyle.Top,Height=50,Multiline=true,Font=new Font("Segoe UI",20),AccessibleName="Campo de teste de foco"};
        input.TextChanged+=(s,e)=>Save();
        status=new Label {Dock=DockStyle.Top,Height=70,Font=new Font("Segoe UI",14),Padding=new Padding(32,18,0,0)};
        var target=new Button {Text="ALVO SOB A JANELA TRANSPARENTE — clique para contar",Dock=DockStyle.Bottom,Height=340,FlatStyle=FlatStyle.Flat,BackColor=Color.FromArgb(37,72,84),ForeColor=Color.FromArgb(232,221,195),Font=new Font("Segoe UI",14),AccessibleName="Alvo de passagem de clique"};
        target.Click+=(s,e)=>{clicks++;Save();};
        Controls.Add(status);Controls.Add(input);Controls.Add(hint);Controls.Add(title);Controls.Add(target);
        Activated+=(s,e)=>Save();Deactivate+=(s,e)=>Save();
        Shown+=(s,e)=>{input.Focus();Save();};
    }
    void Save() {
        status.Text="Cliques recebidos: "+clicks+" | Caracteres no campo: "+input.Text.Length;
        File.WriteAllText(report,"{\"clicks\":"+clicks+",\"characters\":"+input.Text.Length+",\"inputFocused\":"+input.Focused.ToString().ToLowerInvariant()+"}");
    }
    [STAThread] static void Main(string[] args) {
        Application.EnableVisualStyles();Application.SetCompatibleTextRenderingDefault(false);
        Application.Run(new OverlayTestBed(args[0]));
    }
}
