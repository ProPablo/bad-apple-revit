using Autodesk.Revit.DB;
using Autodesk.Revit.UI;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Numerics;
using System.Text;
using System.Threading.Tasks;

namespace BadRevitPlugin
{
    public class CameraAnimator
    {
        // Start and end camera poses
        public ViewOrientation3D StartOrientation;
        public ViewOrientation3D EndOrientation;

        // Quaternions for rotation interpolation
        private Quaternion startRotation;
        private Quaternion endRotation;

        // Animation progress (0.0 to 1.0)
        public double _progress = 0.0;
        private double _progressStep = 0.01; // Increment per frame
        double _totalFrames = 50;

        UIView activeUIView;

        XYZ tl2DView = new XYZ(-136.325334491067, -385.757556358248, 0);
        XYZ br2DView = new XYZ(639.880103568607, 25.133488540549, 0);


        public XYZ start_tl3DView = new XYZ(-132.559041647816, -368.472920520816, -234.351175102827);
        public XYZ start_br3DView = new XYZ(636.207529692398, 35.1842552088059, -211.155246657287);

        XYZ end_tlView = new XYZ(-80.9455112612369, -391.319655354013, -289.627596686653);
        XYZ end_brView = new XYZ(288.645929776608, 303.619236838641, 35.7198544681565);

        public CameraAnimator(int totalFrames)
        {
            {

                XYZ eyePos = new XYZ(-5.19444907657589, -19.1078684286434, -12.9939517178807);
                XYZ upDir = new XYZ(-0.512543360516794, 0.439802436244427, 0.737477539090933);
                XYZ forwardDir = new XYZ(-0.559675862185699, 0.480245822418388, -0.675371660151935);


                // new
                //XYZ eyePos = new XYZ(189.712647391503, 6.03937421696475, -212.889960955653);
                //XYZ upDir = new XYZ(0.00267616633981158, 0.998366046765191, 0.0570795480024686);
                //XYZ forwardDir = new XYZ(0.000153003817345909, 0.0570793429359344, -0.998369635352541);

                StartOrientation = new ViewOrientation3D(eyePos, upDir, forwardDir);
            }

            {

                XYZ eyePos = new XYZ(-39.1125166171924, -32.8130024365151, -31.0643017417252);
                XYZ upDir = new XYZ(0.365390209958605, 0.488754163911767, 0.792218001389338);
                XYZ forwardDir = new XYZ(0.474353638614843, 0.634506097100867, -0.610238181593617);

                //new
                //XYZ eyePos = new XYZ(2.96461334285936, -7.48824499257227, 10.293689070691);
                //XYZ upDir = new XYZ(-0.408248290463863, 0.408248290463863, 0.816496580927726);
                //XYZ forwardDir = new XYZ(-0.577350269189626, 0.577350269189626, -0.577350269189626);

                //XYZ eyePos = new XYZ(0,0, 10.6693712775483);
                //XYZ upDir = new XYZ(0, 1, 0);
                //XYZ forwardDir = new XYZ(0, 0, -1);

                EndOrientation = new ViewOrientation3D(eyePos, upDir, forwardDir);
            }

            _progressStep = 1.0 / (double)totalFrames;

            // Convert view orientations to quaternions
            startRotation = ViewOrientationToQuaternion(StartOrientation);
            //endRotation = ViewOrientationToQuaternion(end);

            var uidoc = BadApple.Application.ActiveUIDocument;
            activeUIView = uidoc.GetOpenUIViews().FirstOrDefault(uv => uv.ViewId == uidoc.ActiveView.Id);

        }

        public void Tick()
        {
            var resources = BadApple.Resources;
            var activeView3D = resources.doc.ActiveView as View3D;
            if (activeView3D != null)
            {
                // Animate camera
                using (Transaction trans = new Transaction(resources.doc, "Animate Camera"))
                {
                    trans.Start();
                    ViewOrientation3D newOrientation = GetCurrentOrientation();
                    activeView3D.SetOrientation(newOrientation);
                    activeView3D.SaveOrientation();
                    trans.Commit();
                }

                //var lerpedViewRectTL = Lerp(start_tl3DView, end_tlView, _progress);
                //var lerpedViewRectBR = Lerp(start_br3DView, end_brView, _progress);

                //activeUIView.ZoomAndCenterRectangle(lerpedViewRectTL, lerpedViewRectBR);

                IncrementProgress();
            }
            //2D view
            else
            {
                activeUIView.ZoomAndCenterRectangle(tl2DView, br2DView);
            }
        }

        public ViewOrientation3D GetCurrentOrientation()
        {
            if (_progress >= 1.0)
                return EndOrientation;

            // Interpolate eye position (simple linear interpolation)
            XYZ eyePos = Lerp(StartOrientation.EyePosition, EndOrientation.EyePosition, _progress);

            // Interpolate rotation using quaternion slerp
            Quaternion currentRotation = Quaternion.Slerp(startRotation, endRotation, (float)_progress);

            // Convert quaternion back to forward and up vectors
            (XYZ forward, XYZ up) = QuaternionToViewVectors(currentRotation);

            return new ViewOrientation3D(eyePos, up, forward);
        }

        public void IncrementProgress()
        {
            _progress = Math.Min(_progress + _progressStep, 1.0);
        }

        public void Reset()
        {
            _progress = 0.0;
        }

        // Linear interpolation for vectors
        private XYZ Lerp(XYZ start, XYZ end, double t)
        {
            return new XYZ(
                start.X + (end.X - start.X) * t,
                start.Y + (end.Y - start.Y) * t,
                start.Z + (end.Z - start.Z) * t
            );
        }

        /// <summary>
        /// Converts a ViewOrientation3D to a Quaternion representing the camera rotation
        /// </summary>
        public Quaternion ViewOrientationToQuaternion(ViewOrientation3D orientation)
        {
            XYZ forward = orientation.ForwardDirection.Normalize();
            XYZ up = orientation.UpDirection.Normalize();

            // Calculate right vector (ensures orthogonality)
            XYZ right = forward.CrossProduct(up).Normalize();

            // Recalculate up to ensure perfect orthogonality
            up = right.CrossProduct(forward).Normalize();

            // Create rotation matrix from basis vectors
            // In a typical right-handed coordinate system:
            // Right = X axis
            // Up = Y axis  
            // -Forward = Z axis (negative because camera looks down -Z)

            // Build a rotation matrix
            //Matrix4x4 rotationMatrix = new Matrix4x4(
            //    (float)right.X, (float)right.Y, (float)right.Z, 0,
            //    (float)up.X, (float)up.Y, (float)up.Z, 0,
            //    (float)-forward.X, (float)-forward.Y, (float)-forward.Z, 0,
            //    0, 0, 0, 1
            //);

            //New lol
            Matrix4x4 rotationMatrix = new Matrix4x4(
              (float)right.X, (float)up.X, (float)-forward.X, 0,  // Row 1: X components
              (float)right.Y, (float)up.Y, (float)-forward.Y, 0,  // Row 2: Y components
              (float)right.Z, (float)up.Z, (float)-forward.Z, 0,  // Row 3: Z components
              0, 0, 0, 1   // Row 4: homogeneous
          );

            // Extract quaternion from rotation matrix
            Quaternion quat = Quaternion.CreateFromRotationMatrix(rotationMatrix);
            return quat;
        }

        /// <summary>
        /// Converts a Quaternion back to forward and up vectors for ViewOrientation3D
        /// </summary>
        public (XYZ forward, XYZ up) QuaternionToViewVectors(Quaternion quat)
        {
            // Convert quaternion to rotation matrix
            Matrix4x4 matrix = Matrix4x4.CreateFromQuaternion(quat);

            // Extract the basis vectors from the rotation matrix
            // Right vector (X axis) = first column
            // Up vector (Y axis) = second column
            // -Forward vector (Z axis) = third column (negated because camera looks down -Z)


            Vector3 upVec = new Vector3(matrix.M12, matrix.M22, matrix.M32);
            Vector3 forwardVec = new Vector3(-matrix.M13, -matrix.M23, -matrix.M33);

            // Convert System.Numerics.Vector3 to Autodesk.Revit.DB.XYZ
            XYZ up = new XYZ(upVec.X, upVec.Y, upVec.Z);
            XYZ forward = new XYZ(forwardVec.X, forwardVec.Y, forwardVec.Z);

            up = up.Normalize();
            forward = forward.Normalize();

            //Make sure forward and up are orthogonal
            XYZ right = forward.CrossProduct(up).Normalize();
            up = forward.CrossProduct(-right).Normalize();


            return (forward.Normalize(), up.Normalize());
        }
    }
}
