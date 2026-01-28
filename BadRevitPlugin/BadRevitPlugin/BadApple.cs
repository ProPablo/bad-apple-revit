using Autodesk.Revit.DB;
using Autodesk.Revit.UI;
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
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

            var panel = application.CreateRibbonPanel(tabName, title);

            panel.Name = title;
            panel.Title = title;
            panel.Visible = true;
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

            application.Idling += Application_Idling;

            return Result.Succeeded;
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
            throw new NotImplementedException();
        }
    }
}
