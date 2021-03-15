using Godot;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using TriangleNet.Geometry;
using TriangleNet.Meshing;
using TriangleNet.Topology;

[Tool]
public class SandboxTriangulation : ColorRect
{
    private IMesh _mesh;
    private Polygon2D _boundary;
    private MultiMeshInstance2D _edges;
    private MultiMeshInstance2D _coloredTriangles;

    private const float MAX_TRIANGLE_AREA = 50f;

    public override void _Ready()
    {
        _boundary = GetNode("Boundary") as Polygon2D;
        _edges = GetNode("Edges") as MultiMeshInstance2D;
        _coloredTriangles = GetNode("ColoredTriangles") as MultiMeshInstance2D;
    }

    public override void _Draw()
    {
        var options = new ConstraintOptions() { ConformingDelaunay = true };
        var quality = new QualityOptions() { MinimumAngle = 25, MaximumArea = MAX_TRIANGLE_AREA };

        TimeSpan time = Time(() =>
        {
            _mesh = GodotPolygonsToTriangle(_boundary, new List<Polygon2D>())
                .Triangulate(options);

            _mesh.Refine(quality, true);
            // var smoother = new SimpleSmoother();
            // smoother.Smooth(_mesh);
            // smoother.Smooth(_mesh);
        });
        GD.Print($"Triangulation time: {time.TotalMilliseconds} ms");

        time = Time(() =>
        {
            _edges.Multimesh = EdgesToMultiMesh(_mesh.Vertices.ToArray(), _mesh.Edges.ToArray());
        });
        // GD.Print($"Draw edge time: {time.TotalMilliseconds} ms");

        time = Time(() =>
        {
            _coloredTriangles.Multimesh = TrianglesToMultiMesh(_mesh.Triangles.ToArray());
        });
        // GD.Print($"Draw triangles time: {time.TotalMilliseconds} ms");

        // time = Time(() =>
        // {
        // 	DrawToCanvas();
        // });
        // GD.Print($"Draw triangles time: {time.TotalMilliseconds} ms");

    }

    public static MultiMesh TrianglesToMultiMesh(Triangle[] triangles)
    {
        var s1 = new Vector3(0, 0, 0);
        var s2 = new Vector3(1, 0, 0);
        var s3 = new Vector3(0, 1, 0);

        var draw = new SurfaceTool();
        draw.Begin(Mesh.PrimitiveType.Triangles);
        draw.AddColor(new Color(1, 1, 1, 1));
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
            color = new Color(1, 0, 0, triangle.CalculateArea() / MAX_TRIANGLE_AREA);
            multimesh.SetInstanceColor(i, color);
        }

        return multimesh;
    }

    public static MultiMesh EdgesToMultiMesh(Vertex[] vertices, Edge[] edges)
    {
        var draw = new SurfaceTool();
        draw.Begin(Mesh.PrimitiveType.Lines);
        draw.AddColor(new Color(0, 0, 0, 1));
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

        return multimesh;
    }

    // The slow way - draw each primitive one at a time
    public void DrawToCanvas()
    {
        Vertex[] vertices = _mesh.Vertices.ToArray();
        var color = new Color(0, 0, 0, 1);

        Vector2 start, end;
        Vertex p1, p2, p3;
        Vector2[] points;
        Color[] colors;

        foreach (var edge in _mesh.Edges)
        {
            start = new Vector2((float)vertices[edge.P0].x, (float)vertices[edge.P0].y);
            end = new Vector2((float)vertices[edge.P1].x, (float)vertices[edge.P1].y);
            DrawLine(start, end, color, 1, true);
        }

        foreach (var triangle in _mesh.Triangles)
        {
            p1 = triangle.GetVertex(0);
            p2 = triangle.GetVertex(1);
            p3 = triangle.GetVertex(2);

            points = new Vector2[] {
                new Vector2((float)p1.x, (float)p1.y),
                new Vector2((float)p2.x, (float)p2.y),
                new Vector2((float)p3.x, (float)p3.y)
            };
            color = new Color(1, 0, 0, triangle.CalculateArea() / MAX_TRIANGLE_AREA);
            colors = new Color[] {
                color,
                color,
                color
            };

            DrawPolygon(points, colors, antialiased: true);
        }
    }

    private IPolygon GodotPolygonsToTriangle(Polygon2D boundary, IEnumerable<Polygon2D> holes)
    {
        IPolygon polygon = boundary.Polygon.ToTrianglePolygon();
        foreach (Polygon2D hole in holes)
        {
            polygon.AddHole(hole.Polygon);
        }
        return polygon;
    }

    public static TimeSpan Time(Action action)
    {
        Stopwatch stopwatch = Stopwatch.StartNew();
        action();
        stopwatch.Stop();
        return stopwatch.Elapsed;
    }

    public void _OnBoundaryDraw()
    {
        if (Engine.EditorHint)
            Update();
    }
}

