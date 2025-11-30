using Google.Protobuf;
using Grpc.Core;
using Grpc.Net.Client;
using Microsoft.AspNetCore.Components.Forms;
using OpenCvSharp;
using OpenPoseStream; // .proto から生成された名前空間
using System.Collections.Concurrent;
using System.Collections.Immutable;
using System.Drawing;
using System.IO;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Threading.Tasks;
using static System.Net.WebRequestMethods;
using OpenPoseServer;

Constructor constructor = new();

HttpClient httpClient = new HttpClient(); 

var builder = WebApplication.CreateBuilder(args);

var logService = new Log("logs.json");
builder.Services.AddSingleton(logService);

builder.Services.ConfigureHttpJsonOptions(options =>
{
    options.SerializerOptions.TypeInfoResolverChain.Insert(0, new AppJsonSerializerContext());
});

var app = builder.Build();

app.UseDefaultFiles();
app.UseStaticFiles();
app.UseCors();

app.MapGet("/api/logs", (Log logger) =>
{
    return logger.GetLogs();
});

app.MapPost("/api/register", (WorkerRegistrationRequest request, Log logger) =>
{
    if (request == null || string.IsNullOrEmpty(request.Url))
    {
        return Results.BadRequest("URLがありません。");
    }

    constructor.availableWorkers.ControlWorkers(request.Url, "Add");

    string msg = $"[API] ワーカー登録: {request.Url}";
    Console.WriteLine(msg);
    logger.AddLog(msg, "SUCCESS");


    return Results.Ok("登録完了");
});

app.MapPost("/api/start-job", async (JobRequest job, Log logger) =>
{

    if (job == null)
    {
        return Results.BadRequest("不明な通信です");
    }

    void Log(string m, string t)
    {
        Console.WriteLine(m);
        logger.AddLog(m, t);
    }

    if (job.Mode == "1")
    {
        if (string.IsNullOrEmpty(job.VideoPathRight))
        {
            Log("メインの動画がありません", "ERROR");
            return Results.BadRequest("メインの動画がありません");
        }
        if (string.IsNullOrEmpty(job.SerialNumberRight))
        {
            Log("メインカメラのシリアルナンバーがありません", "ERROR");
            return Results.BadRequest("メインカメラのシリアルナンバーがありません");
        }

        Log($"[API] ジョブ開始: {job.VideoPathRight}", "INFO");
        Log($"[API] カメラシリアルナンバー: {job.SerialNumberRight}", "INFO");

        _ = Task.Run(() => constructor.singleProcess.SingleRunMainJobDispatcher(job.VideoPathRight, int.Parse(job.Mode), job.SerialNumberRight));
    }
    else if (job.Mode == "0")
    {
        if (string.IsNullOrEmpty(job.VideoPathRight) || string.IsNullOrEmpty(job.VideoPathLeft))
        {
            Log("左右どちらかの動画がありません", "ERROR");
            return Results.BadRequest("左右どちらかの動画がありません");
        }
        if (string.IsNullOrEmpty(job.SerialNumberRight) || string.IsNullOrEmpty(job.SerialNumberLeft))
        {
            Log("左右どちらかのシリアルナンバーがありません", "ERROR");
            return Results.BadRequest("左右どちらかのシリアルナンバーがありません");
        }

        Log($"[API] ジョブ開始: {job.VideoPathRight} | {job.VideoPathLeft}", "INFO");
        Log($"[API] カメラシリアルナンバー: {job.SerialNumberRight} | {job.SerialNumberLeft}", "INFO");

        _ = Task.Run(() => constructor.multiProcess.MultiRunMainJobDispatcher(job.VideoPathLeft, job.VideoPathRight, job.SerialNumberRight, job.SerialNumberRight, int.Parse(job.Mode)));
    }

    return Results.Ok("ジョブを開始しました。");
});

Console.WriteLine("[Server] マスターサーバーを http://localhost:5000 で起動します。");
Console.WriteLine("[Server] ブラウザで http://localhost:5000 を開いてください。");
app.Run("http://*:5000");