using Godot;
using System.Linq;
using TriangleNet.Geometry;

public static class PolygonExtensions
{
    public static IPolygon ToTrianglePolygon(this Vector2[] boundary)
    {
        var polygon = new Polygon();
        polygon.Add(new Contour(boundary.Select(v => new Vertex(v.x, v.y))));
        return polygon;
    }

    public static IPolygon AddHole(this IPolygon polygon, Vector2[] hole)
    {
        polygon.Add(new Contour(hole.Select(v => new Vertex(v.x, v.y))), true);
        return polygon;
    }
}