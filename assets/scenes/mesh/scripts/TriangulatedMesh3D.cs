using Godot;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using TriangleNet.Geometry;
using TriangleNet.Meshing;
using TriangleNet.Smoothing;
using TriangleNet.Topology;

[Tool]
public class TriangulatedMesh3D : Spatial
{
    CSGPolygon _boundary;
    CSGPolygon _hole;
    IMesh _mesh;
    MultiMeshInstance _edges;
    MultiMeshInstance _coloredTriangles;

    SpatialMaterial _edgeMaterial;
    SpatialMaterial _triangleMaterial;


    const float MAX_TRIANGLE_AREA = 0.01f;
    const float IMPERIAL_TO_METRIC = 0.0254f;

    // Called when the node enters the scene tree for the first time.
    public override void _Ready()
    {
        _boundary = GetNode("Boundary") as CSGPolygon;
        _hole = GetNode("Boundary/Hole") as CSGPolygon;
        _edges = GetNode("Edges") as MultiMeshInstance;
        _coloredTriangles = GetNode("ColoredTriangles") as MultiMeshInstance;

        // DrawEdgesAndTriangles();
    }

    void DrawEdgesAndTriangles()
    {
        var options = new ConstraintOptions() { ConformingDelaunay = true };
        var quality = new QualityOptions() { MinimumAngle = 25, MaximumArea = MAX_TRIANGLE_AREA };

        _edgeMaterial = GD.Load<SpatialMaterial>("res://materials/wireframe_dark.tres");
        _triangleMaterial = GD.Load<SpatialMaterial>("res://materials/semi_transparent_uncolored.tres");

        _mesh = GodotPolygonsToTriangle(_boundary, _hole)
            .Triangulate(options, quality);

        _mesh.Refine(quality, true);
        var smoother = new SimpleSmoother();
        smoother.Smooth(_mesh);
        _mesh.Refine(quality, true);
        smoother.Smooth(_mesh);
        _mesh.Refine(quality, true);
        smoother.Smooth(_mesh);
        _mesh.Refine(quality, true);

        _edges.Multimesh = EdgesToMultiMesh(_mesh.Vertices.ToArray(), _mesh.Edges.ToArray());
        _edges.Multimesh.Mesh.SurfaceSetMaterial(0, _edgeMaterial);

        _coloredTriangles.Multimesh = TrianglesToMultiMesh(_mesh.Triangles.ToArray());
        _coloredTriangles.Multimesh.Mesh.SurfaceSetMaterial(0, _triangleMaterial);
    }

    IPolygon GodotPolygonsToTriangle(CSGPolygon boundary, CSGPolygon hole)
    {
        IPolygon polygon = boundary.Polygon.ToTrianglePolygon();

        Vector2[] hole_points = hole.Polygon;
        // TODO need to come up with Units strategy. This is such a hack, it's embarassing.
        hole_points = ScalePoints(hole_points, IMPERIAL_TO_METRIC);
        Vector3 hole_translation = hole.Translation;
        hole_points = MovePoints(hole_points, new Vector2(hole_translation.x, hole_translation.y));
        polygon.AddHole(hole_points);

        return polygon;
    }

    Vector2[] ScalePoints(Vector2[] points, float factor)
    {
        return points.Select(p => factor * p).ToArray();
    }

    Vector2[] MovePoints(Vector2[] points, Vector2 offset)
    {
        return points.Select(p => offset + p).ToArray();
    }

    public static MultiMesh EdgesToMultiMesh(Vertex[] vertices, Edge[] edges)
    {
        var draw = new SurfaceTool();
        draw.Begin(Mesh.PrimitiveType.Lines);
        draw.AddVertex(new Vector3(0, 0, 0));
        draw.AddVertex(new Vector3(1, 1, 0));

        var multimesh = new MultiMesh();
        multimesh.Mesh = draw.Commit();

        multimesh.TransformFormat = MultiMesh.TransformFormatEnum.Transform2d;
        multimesh.ColorFormat = MultiMesh.ColorFormatEnum.None;
        multimesh.CustomDataFormat = MultiMesh.CustomDataFormatEnum.None;
        multimesh.InstanceCount = edges.Length;
        multimesh.VisibleInstanceCount = -1;

        Edge edge;
        Vector2 start;
        Vector2 end;
        Vector2 diff;
        Transform2D transform;

        for (int i = 0; i < multimesh.InstanceCount; i++)
        {
            edge = edges[i];

            start = new Vector2((float)vertices[edge.P0].x, (float)vertices[edge.P0].y);
            end = new Vector2((float)vertices[edge.P1].x, (float)vertices[edge.P1].y);
            diff = end - start;

            // Use a shearing transform to do our bidding
            transform = new Transform2D(new Vector2(1, diff.y - 1), new Vector2(diff.x - 1, 1), start);
            multimesh.SetInstanceTransform2d(i, transform);
        }

        GD.Print($"Drawing {edges.Length} edges");

        return multimesh;
    }

    public static MultiMesh TrianglesToMultiMesh(Triangle[] triangles)
    {
        var s1 = new Vector3(0, 0, 0);
        var s2 = new Vector3(1, 0, 0);
        var s3 = new Vector3(0, 1, 0);

        var draw = new SurfaceTool();
        draw.Begin(Mesh.PrimitiveType.Triangles);
        draw.AddVertex(s1);
        draw.AddVertex(s2);
        draw.AddVertex(s3);

        var multimesh = new MultiMesh();
        multimesh.Mesh = draw.Commit();

        multimesh.TransformFormat = MultiMesh.TransformFormatEnum.Transform2d;
        multimesh.ColorFormat = MultiMesh.ColorFormatEnum.Color8bit;
        multimesh.CustomDataFormat = MultiMesh.CustomDataFormatEnum.None;
        multimesh.InstanceCount = triangles.Length;
        multimesh.VisibleInstanceCount = -1;

        Triangle triangle;
        Vertex t1, t2, t3;
        double a1, a2, a3, a4, a5, a6;
        Transform2D transform;
        Color color;

        for (int i = 0; i < multimesh.InstanceCount; i++)
        {
            triangle = triangles[i];

            t1 = triangle.GetVertex(0);
            t2 = triangle.GetVertex(1);
            t3 = triangle.GetVertex(2);

            /* To utilize the multimesh, we used the same triangle for all instances and apply an affine transformation per
			*  https://stackoverflow.com/questions/1114257/transform-a-triangle-to-another-triangle
			*/
            a1 = ((t1.x - t2.x) * (s1.y - s3.y) - (t1.x - t3.x) * (s1.y - s2.y)) /
                 ((s1.x - s2.x) * (s1.y - s3.y) - (s1.x - s3.x) * (s1.y - s2.y));
            a2 = ((t1.x - t2.x) * (s1.x - s3.x) - (t1.x - t3.x) * (s1.x - s2.x)) /
                 ((s1.y - s2.y) * (s1.x - s3.x) - (s1.y - s3.y) * (s1.x - s2.x));
            a3 = t1.x - a1 * s1.x - a2 * s1.y;
            a4 = ((t1.y - t2.y) * (s1.y - s3.y) - (t1.y - t3.y) * (s1.y - s2.y)) /
                 ((s1.x - s2.x) * (s1.y - s3.y) - (s1.x - s3.x) * (s1.y - s2.y));
            a5 = ((t1.y - t2.y) * (s1.x - s3.x) - (t1.y - t3.y) * (s1.x - s2.x)) /
                 ((s1.y - s2.y) * (s1.x - s3.x) - (s1.y - s3.y) * (s1.x - s2.x));
            a6 = t1.y - a4 * s1.x - a5 * s1.y;

            transform = new Transform2D((float)a1, (float)a4, (float)a2, (float)a5, (float)a3, (float)a6);
            multimesh.SetInstanceTransform2d(i, transform);

            // Change opacity based on triangle area
            color = new Color(1, 0, 0, triangle.CalculateArea() / (MAX_TRIANGLE_AREA * 4));
            multimesh.SetInstanceColor(i, color);
        }

        GD.Print($"Drawing {triangles.Length} triangles");

        return multimesh;
    }

    void _onHoleChanged()
    {
        DrawEdgesAndTriangles();
    }
}
