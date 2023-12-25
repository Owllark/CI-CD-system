using aspnetcoreapp.Services;

namespace app.unittest;

public class Tests
{
    [SetUp]
    public void Setup()
    {
    }

    [Test]
    public void TestAddition()
    {
        // Arrange
        var calculator = new CalculatorService();

        // Act
        var result = calculator.Add(2, 3);

        // Assert
        Assert.AreEqual(5, result);
    }
}