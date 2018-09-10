using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Windows.Forms;

namespace auto_install
{
    public partial class frmMain : Form
    {
        private string ExecutionPath = string.Empty;
        private string ConfigPath = string.Empty;
        private string GamePath = string.Empty;
        private string ModPath = string.Empty;
        private bool BackupDone = false;

        public frmMain()
        {
            InitializeComponent();
            ExecutionPath = Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location);

            textBox1.Text = ExecutionPath;
        }

        private void button1_Click(object sender, EventArgs e)
        {
            folderBrowserDialog1.SelectedPath = ExecutionPath;
            if (folderBrowserDialog1.ShowDialog() == DialogResult.OK)
            {
                textBox2.Text = GamePath = folderBrowserDialog1.SelectedPath;
                SavePathToFile();
            }
        }

        private void button4_Click(object sender, EventArgs e)
        {
            if (GamePath == string.Empty)
            {
                MessageBox.Show("Game path not loaded", "ERROR", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }
            if (ModPath == string.Empty)
            {
                MessageBox.Show("Mod path not loaded", "ERROR", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }

            // Install
            // Replace files
            if (!BackupDone)
            {
                var result = MessageBox.Show("Do you want to backup files before replacing them ?", "Backup", MessageBoxButtons.YesNoCancel, MessageBoxIcon.Warning);

                if (result == DialogResult.Cancel)
                {
                    return;
                }
                if (result == DialogResult.Yes)
                {
                    Backup();
                }
            }

            string pathModData = Path.Combine(ModPath, @"AdvancedReadme\Data");
            if (!Directory.Exists(pathModData))
            {
                MessageBox.Show(@"""$MOD_PATH/AdvancedReadme/Data"" not found", "ERROR", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }

            DirectoryInfo directoryInfo = new DirectoryInfo(pathModData);
            FullDirList(directoryInfo, "*");

            // Create directories not present in game data
            foreach (var item in folders)
            {
                string gameFolder = item.FullName.Replace(pathModData, GamePath);
                if (!Directory.Exists(gameFolder))
                    Directory.CreateDirectory(gameFolder);
            }

            // Look for required files to install
            List<string> filesToInstall = new List<string>();
            foreach (var file in files)
            {
                string filePath = file.FullName;
                if (File.Exists(filePath))
                {
                    filesToInstall.Add(filePath);
                }
            }

            foreach (var item in filesToInstall)
            {
                string dest = item.Replace(pathModData, GamePath);
                Console.WriteLine($"Replacing {dest} by {item}");
                File.Copy(item, dest, true);
            }

            MessageBox.Show("Installation Complete !", "Information", MessageBoxButtons.OK);
            Close();
        }

        private void button2_Click(object sender, EventArgs e)
        {
            // Make backup
            Backup();
        }

        private void Backup()
        {
            if (GamePath == string.Empty)
            {
                MessageBox.Show("Game path not loaded", "ERROR", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }
            if (ModPath == string.Empty)
            {
                MessageBox.Show("Mod path not loaded", "ERROR", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }

            string pathModData = Path.Combine(ModPath, @"AdvancedReadme\Data");
            DirectoryInfo directoryInfo = new DirectoryInfo(pathModData);
            FullDirList(directoryInfo, "*");

            List<string> filesToBackup = new List<string>();
            foreach (var file in files)
            {
                string filePath = file.FullName;
                filePath = filePath.Replace(pathModData, GamePath);
                if (File.Exists(filePath))
                {
                    filesToBackup.Add(filePath);
                }
            }

            string backupPath = Path.Combine(GamePath, @"backup\");
            if (!Directory.Exists(backupPath))
            {
                Directory.CreateDirectory(backupPath);
            }

            foreach (var item in filesToBackup)
            {
                string dest = Path.Combine(backupPath, Path.GetFileName(item));
                File.Copy(item, dest, false);
            }

            BackupDone = true;
            Console.WriteLine("Backup complete");
            MessageBox.Show("Backup complete");
        }

        private void RestoreBackup()
        {
            if (GamePath == string.Empty)
            {
                MessageBox.Show("Game path not loaded", "ERROR", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }
            if (ModPath == string.Empty)
            {
                MessageBox.Show("Mod path not loaded", "ERROR", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }
            string backupPath = Path.Combine(GamePath, @"backup\");
            if (!Directory.Exists(backupPath))
            {
                MessageBox.Show("No backup found");
                return;
            }

            string pathModData = Path.Combine(ModPath, @"AdvancedReadme\Data");
            DirectoryInfo directoryInfo = new DirectoryInfo(pathModData);
            FullDirList(directoryInfo, "*");

            // Look for required files to restore
            List<string> destinationFiles = new List<string>();
            foreach (var file in files)
            {
                string filePath = file.FullName;
                filePath = filePath.Replace(pathModData, GamePath);
                destinationFiles.Add(filePath);
            }

            foreach (var item in destinationFiles)
            {
                string source = Path.Combine(backupPath, Path.GetFileName(item));
                if (File.Exists(source))
                {
                    File.Copy(source, item, true);
                }
            }

            Console.WriteLine("Backup restore complete");
            MessageBox.Show("Backup restore complete");
        }

        List<FileInfo> files = new List<FileInfo>();  // List that will hold the files and subfiles in path
        List<DirectoryInfo> folders = new List<DirectoryInfo>(); // List that hold direcotries that cannot be accessed
        void FullDirList(DirectoryInfo dir, string searchPattern)
        {
            // Console.WriteLine("Directory {0}", dir.FullName);
            // list the files
            try
            {
                foreach (FileInfo f in dir.GetFiles(searchPattern))
                {
                    //Console.WriteLine("File {0}", f.FullName);
                    files.Add(f);
                }
            }
            catch
            {
                Console.WriteLine("Directory {0}  \n could not be accessed!!!!", dir.FullName);
                return;  // We alredy got an error trying to access dir so dont try to access it again
            }

            // process each directory
            // If I have been able to see the files in the directory I should also be able 
            // to look at its directories so I dont think I should place this in a try catch block
            foreach (DirectoryInfo d in dir.GetDirectories())
            {
                folders.Add(d);
                FullDirList(d, searchPattern);
            }
        }

        private void button3_Click(object sender, EventArgs e)
        {
            // Restore backup
            RestoreBackup();
        }

        private void button5_Click(object sender, EventArgs e)
        {
            // Load mod data folder
            folderBrowserDialog1.SelectedPath = ExecutionPath;
            if (folderBrowserDialog1.ShowDialog() == DialogResult.OK)
            {
                textBox3.Text = folderBrowserDialog1.SelectedPath;
                var directories = Directory.GetDirectories(folderBrowserDialog1.SelectedPath);
                if (!directories.Contains(folderBrowserDialog1.SelectedPath + "\\Mod_EsseivaN"))
                {
                    MessageBox.Show("Invalid mod data folder. Check again", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
                else
                {
                    ModPath = folderBrowserDialog1.SelectedPath;
                    SavePathToFile();
                }
            }
        }

        private void textBox2_TextChanged(object sender, EventArgs e)
        {
            GamePath = textBox2.Text;
            SavePathToFile();
        }

        private void textBox3_TextChanged(object sender, EventArgs e)
        {
            ModPath = textBox3.Text;
            SavePathToFile();
        }

        private void frmMain_Load(object sender, EventArgs e)
        {
            LoadPathFromFile();
        }

        private void SavePathToFile()
        {
            try
            {
                if(GamePath != string.Empty && ModPath != string.Empty)
                {
                    string path = Path.Combine(ExecutionPath, "config.esseivan");
                    string data = $"{GamePath}\n{ModPath}";
                    File.WriteAllText(path, data);
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("Unable to save path to config file. The application will still work normally", "Information", MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
        }

        private void LoadPathFromFile()
        {
            string path = Path.Combine(ExecutionPath, "config.esseivan");
            if(File.Exists(path))
            {
                // Config existing, reading path
                string data = File.ReadAllText(path);
                string[] lines = data.Split(new char[] { '\n' }, StringSplitOptions.RemoveEmptyEntries);
                if(lines.Length >= 2)
                {
                    GamePath = textBox2.Text = lines[0];
                    ModPath = textBox3.Text = lines[1];
                }
            }
        }
    }
}
