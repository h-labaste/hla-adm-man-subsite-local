using GestionSousSite.Features.Configuration.Services;
using GestionSousSite.Features.Sites.Services;
using GestionSousSite.Services;

using MudBlazor.Services;

var builder = WebApplication.CreateBuilder(args);
if (builder == null)
  return;
// Azure Dev Ops Intégration
builder.Services.AddSingleton<AzureDevOpsService>(provider =>
{
  string personalAccessToken = builder.Configuration["AzureDevOps_PAT"]
    ?? throw new ArgumentNullException(nameof(personalAccessToken),
    "AzureDevOps_PAT est manquant dans la configuration.");

  string personalOrganization = builder.Configuration["AzureDevOps_ORG"]
    ?? throw new ArgumentNullException(nameof(personalOrganization),
    "AzureDevOps_ORG est manquant dans la configuration.");

  return new AzureDevOpsService(personalOrganization, personalAccessToken);
});


// Ajouter Singleton Services
builder.Services.AddSingleton<ConfigService>();
builder.Services.AddSingleton<SitesService>();
builder.Services.AddSingleton<PathsService>();
builder.Services.AddSingleton<RewriteRulesService>();

// Ajouter Scoped Services
builder.Services.AddScoped<UserStateService>();

// Add services to the container.
builder.Services.AddRazorPages();
builder.Services.AddServerSideBlazor();

// Services - Packages
builder.Services.AddMudServices();


var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
  app.UseExceptionHandler("/Error");
  app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

app.MapBlazorHub();
app.MapFallbackToPage("/_Host");

app.Run();
