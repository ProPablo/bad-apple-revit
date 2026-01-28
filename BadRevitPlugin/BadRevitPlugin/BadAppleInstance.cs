using Autodesk.Revit.DB;
using Autodesk.Revit.UI;
using MatFileHandler;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BadRevitPlugin
{
    public class BadAppleInstance
    {
        public MatLoader loader;
        public int frameNum = 0;

        public DateTime lastTimeRun;
        public static TimeSpan FRAME_TIME = TimeSpan.FromMilliseconds(20);
        public BadAppleInstance()
        {
            loader = new MatLoader();
            loader.Load();
        }

        public Result DrawFirstFrame()
        {

            var doc = BadApple.Application.ActiveUIDocument.Document;

            IArrayOf<double> firstFrameBoundarydoubles = loader.boundaries[0, 0] as IArrayOf<double>;
            var numPoints = firstFrameBoundarydoubles.Dimensions[0];

            List<XYZ> boundaryPoints = new();

            for (int i = 0; i < numPoints; i++)
            {
                boundaryPoints.Add(new XYZ(firstFrameBoundarydoubles[i, 0], firstFrameBoundarydoubles[i, 1], 0));
            }


            // Example 2D points (in feet) - replace with your actual points
            List<XYZ> points = new List<XYZ>
            {
                new XYZ(0, 0, 0),
                new XYZ(10, 0, 0),
                new XYZ(10, 15, 0),
                new XYZ(0, 15, 0)
            };

            //points = boundaryPoints;

            // Get the active view's level
            Level level = doc.GetElement(doc.ActiveView.GenLevel.Id) as Level;
            if (level == null)
            {
                TaskDialog.Show("Error", "Please open a floor plan view");
                return Result.Failed;
            }
            Transaction transaction = new Transaction(doc);

            transaction.Start("First frame bad apple");

            double wallHeight = 10.0; // 10 feet
            var wallType = GetWallType();

            // Create walls between consecutive points
            for (int i = 0; i < points.Count; i++)
            {
                XYZ start = points[i];
                XYZ end = points[(i + 1) % points.Count]; // Wrap around to close the loop

                Line wallLine = Line.CreateBound(start, end);

                Wall wall = Wall.Create(doc, wallLine, wallType.Id, level.Id, wallHeight, 0, false, false);
            }


            transaction.Commit();


            return Result.Succeeded;
        }


        /// <summary>
        /// This gets the walltype when there are no instances
        /// </summary>
        /// <returns></returns>
        WallType GetWallType()
        {
            var doc = BadApple.Application.ActiveUIDocument.Document;
            // Get a basic wall type
            WallType wallType = new FilteredElementCollector(doc)
                .OfClass(typeof(WallType))
                .FirstOrDefault(w => w.Name.Contains("Wall-Int")) as WallType;

            if (wallType == null)
            {
                wallType = new FilteredElementCollector(doc)
                    .OfClass(typeof(WallType))
                    .FirstOrDefault() as WallType;
            }
            return wallType;
        }


        public void Tick()
        {

        }

    }
}
