using Autodesk.Revit.Attributes;
using Autodesk.Revit.DB;
using Autodesk.Revit.UI;

namespace BadRevitPlugin
{
    [Transaction(TransactionMode.Manual)]
    [Regeneration(RegenerationOption.Manual)]
    public class DrawSingleFrameCommand : IExternalCommand
    {
        private const int FRAME_INDEX = 15; // Change this to draw a different frame
        //private const int FRAME_INDEX = 2; 

        public Result Execute(ExternalCommandData commandData, ref string message, ElementSet elements)
        {
            // Initialize instance if needed
            if (BadApple.Instance == null)
            {
                BadApple.Instance = new BadAppleInstance();
                BadApple.Application = commandData.Application;
                var res = BadApple.Instance.InitResources(commandData.Application.ActiveUIDocument.Document);
                if (res != Result.Succeeded)
                {
                    BadApple.Instance = null;
                    return res;
                }
            }

            BadApple.Instance.isRunning = false;

            // Draw the frame
            return BadApple.Instance.DrawFrame(FRAME_INDEX);
        }
    }
}
