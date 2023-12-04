using Microsoft.AspNetCore.Mvc;
using App.Controllers;


namespace UnitTesting;

[TestClass]
public class HomeControllerTests
{
    [TestMethod]
    public void PrivacyTitle()
    {
        var controller = new HomeController();
        
        var result = controller.Privacy() as ViewResult;

        Assert.IsNotNull(result);
        Assert.AreEqual("Privacy Policy", result.ViewData["Title"]);
    }
}