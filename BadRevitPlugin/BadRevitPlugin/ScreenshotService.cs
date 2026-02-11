using Autodesk.Revit.UI;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace BadRevitPlugin
{
    public class ScreenshotService
    {
        public static void TakeCurrentFrameScreenshot()
        {
            var currentIndex = BadApple.Instance.frameNum;
            TakeIndexedFrameScreenShot(currentIndex);
        }

        public static void TakeIndexedFrameScreenShot(int currentIndex)
        {
            var frameFileName = $"{currentIndex:D4}.jpg";
            TakeSingleScreenshot(frameFileName);
        }

        public static void TakeSingleScreenshot(string picName = "test.jpg")
        {
            System.Drawing.Rectangle bounds = Screen.GetBounds(System.Drawing.Point.Empty);
            using (System.Drawing.Bitmap bitmap = new System.Drawing.Bitmap(bounds.Width, bounds.Height))
            {
                using (System.Drawing.Graphics g = System.Drawing.Graphics.FromImage(bitmap))
                {
                    g.CopyFromScreen(System.Drawing.Point.Empty, System.Drawing.Point.Empty, bounds.Size);
                }

                string filePath = Path.Combine(BadApple.ImgSaveDir, picName);
                bitmap.Save(filePath, System.Drawing.Imaging.ImageFormat.Jpeg);

                //TaskDialog.Show("Screenshot", $"Screenshot saved to:\n{filePath}");
            }

        }
    }
}
