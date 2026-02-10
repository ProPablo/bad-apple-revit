using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Shapes;

namespace BadRevitPlugin
{
    /// <summary>
    /// Interaction logic for SelectFrameNumPopup.xaml
    /// </summary>
    public partial class SelectFrameNumPopup : Window
    {
        public SelectFrameNumPopup()
        {
            InitializeComponent();
            frameTextBox.Text = $"{84}";
            frameTextBox.SelectAll();
            frameTextBox.Focus();
        }

        public int FrameIndex { get; private set; }

        private void OkButton_Click(object sender, RoutedEventArgs e)
        {
            if (int.TryParse(frameTextBox.Text, out int index))
            {
                FrameIndex = index;
                DialogResult = true;
            }
            else
            {
                MessageBox.Show("Please enter a valid integer.", "Invalid Input", MessageBoxButton.OK, MessageBoxImage.Warning);
            }
        }
    }
}
