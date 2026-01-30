using Autodesk.Revit.DB;
using Autodesk.Revit.UI;
using MatFileHandler;
using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;

namespace BadRevitPlugin
{
    public class MatLoader
    {
        public MatLoader()
        {

        }

        public BadAppleContext context;

        public void Load()
        {
            string cwd = System.IO.Directory.GetCurrentDirectory();
            Console.WriteLine($"Current Working Directory: {cwd}");

            // Might have to use this since mat will be located relative to this
            string assemblyWorkingDir = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);
            Console.WriteLine($"Current Working Directory: {assemblyWorkingDir}");

            //TaskDialog.Show("Current Working Dir", cwd);
            //TaskDialog.Show("Assembly Working Dir", otherworkingDir);

            var matRelativeLoc = "../../../../../bad_apple.mat";

            var matFileLoc = Path.Combine(assemblyWorkingDir, matRelativeLoc);
            matFileLoc = Path.GetFullPath(matFileLoc);

            TaskDialog td = new TaskDialog("Mat File Location");
            td.MainInstruction = "Material file path:";
            td.MainContent = "Click 'Show Details' to view full path.";
            td.ExpandedContent = matFileLoc;

            //td.Show();


            IMatFile matFile;
            using (var fileStream = new System.IO.FileStream(matFileLoc, System.IO.FileMode.Open))
            {
                var reader = new MatFileReader(fileStream);
                matFile = reader.Read();
            }

            var frameCount = (int)matFile["num_frames"].Value.ConvertToDoubleArray()[0];
            var boundaries = matFile["simple_bounds"].Value as ICellArray;
            var centroids = matFile["centroids"].Value as ICellArray;

            context = new BadAppleContext();

            for (int f = 0; f < 1; f++)
            {
                var frame = new BadAppleFrame();
                context.frames.Add(frame);

                var numBoundaries = boundaries.Dimensions[1];

                for (int b = 0; b < numBoundaries; b++)
                {
                    var boundaryPoints = boundaries[f, b] as IArrayOf<double>;
                    var centroidArray = centroids[f, b] as IArrayOf<double>;
                    var centroid = new UV(centroidArray[0], centroidArray[1]);

                    var room = RoomBoundary.Create(boundaryPoints, centroid);
                    frame.Rooms.Add(room);
                }
            }
        }
    }

    public class RoomBoundary
    {
        public List<XYZ> MainOuterLoop = new();
        public List<List<XYZ>> InnerLoops = new();
        public UV centroid;

        public static RoomBoundary Create(IArrayOf<double> points, UV centroid)
        {
            var room = new RoomBoundary();
            room.centroid = centroid;

            var numPoints = points.Dimensions[0];

            int innerLoopIdx = -1;

            for (int i = 0; i < numPoints; i++)
            {
                if (double.IsNaN(points[i, 0]))
                {
                    innerLoopIdx++;
                    room.InnerLoops.Add(new List<XYZ>());
                    continue;
                }

                if (innerLoopIdx < 0)
                {
                    room.MainOuterLoop.Add(new XYZ(points[i, 0], points[i, 1], 0));
                }
                else
                {
                    room.InnerLoops[innerLoopIdx].Add(new XYZ(points[i, 0], points[i, 1], 0));
                }
            }

            return room;
        }
    }

    public class BadAppleFrame
    {
        public List<RoomBoundary> Rooms = new();

        public static BadAppleFrame Create(ICellArray boundaries, ICellArray centroids)
        {
            var frame = new BadAppleFrame();


            return frame;
        }
    }

    public class BadAppleContext
    {
        public List<BadAppleFrame> frames = new();
    }
}
