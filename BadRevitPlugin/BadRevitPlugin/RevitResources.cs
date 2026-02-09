using Autodesk.Revit.DB;
using Autodesk.Revit.UI;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BadRevitPlugin
{
    public class RevitResources
    {

       // Pre-init vars

       public Document doc;
       public double wallHeight;
       public WallType wallType;
       public Level level;
       public double ceilingHeight;
       public CeilingType ceilingType;
       public List<ElementId> existingElements;


        public Result InitResources(Document doc)
        {
            this.doc = doc;

            //double wallHeight = 10.0; // 10 feet
            var instancedWalls = GetWalls();

            existingElements = instancedWalls.Select(w => w.Id).ToList();

            var instancedWall = instancedWalls.FirstOrDefault();

            if (instancedWall == null)
            {
                TaskDialog.Show("Error", "Wall not found");
                return Result.Failed;
            }

            // Get its type, level, and height
            wallType = instancedWall.WallType;
            level = doc.GetElement(instancedWall.LevelId) as Level;
            wallHeight = instancedWall.get_Parameter(BuiltInParameter.WALL_USER_HEIGHT_PARAM).AsDouble();


            // Get ceiling type by name
            ceilingType = new FilteredElementCollector(doc)
                .OfClass(typeof(CeilingType))
                .Cast<CeilingType>()
                .FirstOrDefault(c => c.Name.Contains("Epic ceiling"));

            Ceiling ceiling = new FilteredElementCollector(doc)
                .OfClass(typeof(Ceiling))
                .Cast<Ceiling>()
                .FirstOrDefault(c => c.Name.Contains("Epic ceiling"));

            existingElements.Add(ceiling.Id);

            if (ceilingType == null || ceiling == null)
            {
                TaskDialog.Show("Error", "Ceiling type or ceiling not found");
                return Result.Failed;
            }

            Parameter param = ceiling.get_Parameter(BuiltInParameter.CEILING_HEIGHTABOVELEVEL_PARAM);
            ceilingHeight = param.AsDouble();

            Transaction transaction = new Transaction(doc);
            transaction.Start("Removing prev frame items");
            doc.Delete(existingElements);
            transaction.Commit();

            return Result.Succeeded;
        }

        /// <summary>
        /// This gets the walltype when there are no instances
        /// </summary>
        /// <returns></returns>
        List<Wall> GetWalls()
        {
            var doc = BadApple.Application.ActiveUIDocument.Document;
            // Get a basic wall type
            return new FilteredElementCollector(doc)
                .OfClass(typeof(Wall))
                .Cast<Wall>()
                .ToList();
        }

    }
}
