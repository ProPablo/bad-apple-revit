using Autodesk.Revit.Attributes;
using Autodesk.Revit.DB;
using Autodesk.Revit.UI;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BadRevitPlugin
{
    [Transaction(TransactionMode.Manual)]
    [Regeneration(RegenerationOption.Manual)]

    public class RunBadAppleCommand : IExternalCommand
    {
        public Result Execute(ExternalCommandData commandData, ref string message, ElementSet elements)
        {
            if (BadApple.Resources == null)
            {
                BadApple.Application = commandData.Application;
                BadApple.Resources = new RevitResources();
                var res = BadApple.Resources.InitResources(commandData.Application.ActiveUIDocument.Document);

                if (res != Result.Succeeded)
                {
                    BadApple.Instance = null;
                    return res;
                }
            }

            BadApple.Instance = new BadAppleInstance();
            BadApple.Application = commandData.Application;

            return BadApple.Instance.DrawFirstFrame();
        }
    }
}
