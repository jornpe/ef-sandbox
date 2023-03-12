using Dapper;
using Microsoft.Data.SqlClient;

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.UseHttpsRedirection();
app.UseDeveloperExceptionPage();    

app.MapGet("/", () => "Hello World!");
app.MapGet("/con", () => app.Configuration.AsEnumerable().ToList());

app.Map("/test", async () =>
{
    //var connectionstring = @"Server=sqlsrv-ef-test.database.windows.net; Authentication=Active Directory Managed Identity; Encrypt=True; Database=sqlsrv-ef-test";
    var connectionstring = app.Configuration.GetConnectionString("DefaultConnection");
    await using var connection = new SqlConnection(connectionstring);
    await connection.QueryAsync<int>("SELECT 1");

    return "Success!!";
});

app.Run();