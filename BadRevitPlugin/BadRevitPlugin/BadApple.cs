using Autodesk.Revit.DB;
using Autodesk.Revit.UI;
using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Interop;
using System.Windows.Media;
using System.Windows.Media.Imaging;

namespace BadRevitPlugin
{
    public class BadApple : IExternalApplication, IDisposable
    {
        public static BadAppleInstance Instance = null;
        public static UIApplication Application = null;
        public static RevitResources Resources = null;

        public static string BadAppleRoot;
        public static string ImgSaveDir;
        public static string MatPath;


        public BadApple()
        {
            string assemblyWorkingDir = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);
            Console.WriteLine($"Current Working Directory: {assemblyWorkingDir}");

            var matRelativePath = "../../../../../";
            var matName = "bad_apple.mat";

            BadAppleRoot = Path.Combine( assemblyWorkingDir, matRelativePath );
            BadAppleRoot = Path.GetFullPath( BadAppleRoot );

            MatPath = Path.Combine( BadAppleRoot, matName );
            ImgSaveDir = Path.Combine( BadAppleRoot, "imgs" );
        }

        public void Dispose()
        {
            throw new NotImplementedException();
        }

        public Result OnShutdown(UIControlledApplication application)
        {
            return Result.Succeeded;
        }

        public Result OnStartup(UIControlledApplication application)
        {
            var tabName = "Bad Apple";
            application.CreateRibbonTab(tabName);
            var title = "Bad Apple";

            RibbonPanel panel = application.CreateRibbonPanel(tabName, title);

            panel.Name = title;
            panel.Title = title;
            panel.Visible = true;

            CreateMainButton(panel);
            CreateStopButton(panel);
            CreateScreenshotButton(panel);
            CreateRollBackButton(panel);
            CreateDrawSingleFrameButton(panel);
            CreatePrintCameraPoseButton(panel);

            application.Idling += Application_Idling;

            return Result.Succeeded;
        }

        public void CreateMainButton(RibbonPanel panel)
        {
            var label = "START";
            var toolTip = "Once this baby reaches 88 m/h youre gonna see some serious shit";


            var commandType = typeof(RunBadAppleCommand);
            var assembly = commandType.Assembly;
            var name = commandType.FullName;

            var pushButtonData = new PushButtonData(label, label, assembly.Location, name)
            {
                ToolTip = toolTip,
            };

            var icon = Properties.Resources.MainButton;

            var image = GetImageSource(icon);
            pushButtonData.LargeImage = image;

            var downscaledImage = GetResizedImageSource(image, sizeModifier: 0.5d);
            pushButtonData.Image = downscaledImage;

            panel.AddItem(pushButtonData);

        }

        public void CreatePrintCameraPoseButton(RibbonPanel panel)
        {
            var label = "Print Cam";
            var toolTip = "Print current 3D camera position and rotation to console/dialog";

            var commandType = typeof(PrintCameraPoseCommand);
            var assembly = commandType.Assembly;
            var name = commandType.FullName;

            var pushButtonData = new PushButtonData(label, label, assembly.Location, name)
            {
                ToolTip = toolTip,
            };

            panel.AddItem(pushButtonData);
        }


        public void CreateRollBackButton(RibbonPanel panel)
        {
            var label = "Undo";
            var toolTip = "Undo prev frame";


            Type commandType = typeof(UndoPrevFrameCommand);
            Assembly assembly = commandType.Assembly;

            var name = commandType.FullName;

            var pushButtonData = new PushButtonData(label, label, assembly.Location, name)
            {
                ToolTip = toolTip,
            };

            panel.AddItem(pushButtonData);
        }

        public void CreateStopButton(RibbonPanel panel)
        {
            var label = "Stop";
            var toolTip = "Stop frame processing";

            var commandType = typeof(StopCommand);
            var assembly = commandType.Assembly;
            var name = commandType.FullName;

            var pushButtonData = new PushButtonData(label, label, assembly.Location, name)
            {
                ToolTip = toolTip,
            };

            panel.AddItem(pushButtonData);
        }

        public void CreateScreenshotButton(RibbonPanel panel)
        {
            var label = "Screenshot";
            var toolTip = "Capture a screenshot of the current screen";

            var commandType = typeof(ScreenshotCommand);
            var assembly = commandType.Assembly;
            var name = commandType.FullName;

            var pushButtonData = new PushButtonData(label, label, assembly.Location, name)
            {
                ToolTip = toolTip,
            };

            panel.AddItem(pushButtonData);
        }

        public void CreateDrawSingleFrameButton(RibbonPanel panel)
        {
            var label = "Draw Frame";
            var toolTip = "Draw a single frame (frame index is hardcoded in DrawSingleFrameCommand)";

            var commandType = typeof(DrawSingleFrameCommand);
            var assembly = commandType.Assembly;
            var name = commandType.FullName;

            var pushButtonData = new PushButtonData(label, label, assembly.Location, name)
            {
                ToolTip = toolTip,
            };

            panel.AddItem(pushButtonData);
        }

        private ImageSource GetImageSource(Icon resource)
        {
            ImageSource imageSource = Imaging.CreateBitmapSourceFromHIcon(resource.Handle, Int32Rect.Empty, BitmapSizeOptions.FromEmptyOptions());
            return imageSource;

        }

        private ImageSource GetResizedImageSource(ImageSource imageSource, double sizeModifier)
        {
            var bitmapSource = imageSource as BitmapSource;

            var resizedImage = new TransformedBitmap();
            resizedImage.BeginInit();
            resizedImage.Source = bitmapSource;
            resizedImage.Transform = new ScaleTransform(sizeModifier, sizeModifier);
            resizedImage.EndInit();

            return resizedImage;
        }

        private void Application_Idling(object sender, Autodesk.Revit.UI.Events.IdlingEventArgs e)
        {
            if (Instance == null)
            {
                return;
            }

            Instance.Tick();
        }
    }
}
