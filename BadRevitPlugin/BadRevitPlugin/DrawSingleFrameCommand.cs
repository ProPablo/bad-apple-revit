using Autodesk.Revit.Attributes;
using Autodesk.Revit.DB;
using Autodesk.Revit.UI;

namespace BadRevitPlugin
{
    [Transaction(TransactionMode.Manual)]
    [Regeneration(RegenerationOption.Manual)]
    public class DrawSingleFrameCommand : IExternalCommand
    {
        //private const int FRAME_INDEX = 185; // Change this to draw a different frame
        //private const int FRAME_INDEX = 2; 

        public Result Execute(ExternalCommandData commandData, ref string message, ElementSet elements)
        {
            //Might be good case for self managed singleton
            if (BadApple.Resources == null)
            {
                BadApple.Application = commandData.Application;
                BadApple.Resources = new RevitResources();
                var initRes = BadApple.Resources.InitResources(commandData.Application.ActiveUIDocument.Document);

                if (initRes != Result.Succeeded)
                {
                    BadApple.Instance = null;
                    return initRes;
                }
            }

            // Show input dialog
            var inputDialog = new SelectFrameNumPopup();
            bool? result = inputDialog.ShowDialog();

            if (result != true)
            {
                return Result.Cancelled;
            }

            int frameIndex = inputDialog.FrameIndex;


            BadApple.Instance = new BadAppleInstance();
            BadApple.Instance.isRunning = false;

            BadApple.Instance.animator.SetCurrentProgressByAssigningFrame(frameIndex);

            // Draw the frame
            var res = BadApple.Instance.DrawFrame(frameIndex);
            if (res == Result.Succeeded)
            {
                ScreenshotService.TakeIndexedFrameScreenShot(frameIndex);
            }
            return res;
        }
    }
}
