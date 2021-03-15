using TriangleNet.Geometry;
using TriangleNet.Topology;

public static class TriangleExtensions
{
    public static float CalculateArea(this Triangle triangle)
    {
        Vertex p1 = triangle.GetVertex(0);
        Vertex p2 = triangle.GetVertex(1);
        Vertex p3 = triangle.GetVertex(2);

        return (float)(0.5 * (p1.x * (p2.y - p3.y) + p2.x * (p3.y - p1.y) + p3.x * (p1.y - p2.y)));
    }
}