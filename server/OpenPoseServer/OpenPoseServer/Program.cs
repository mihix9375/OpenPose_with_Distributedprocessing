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

ConcurrentBag<string> availableWorkerUrls = new ConcurrentBag<string>();
HttpClient httpClient = new HttpClient(); 
SingleProcess singleProcess = new SingleProcess();
MultiProcess multiProcess = new MultiProcess();

var builder = WebApplication.CreateBuilder(args);

builder.Services.ConfigureHttpJsonOptions(options =>
{
    options.SerializerOptions.TypeInfoResolverChain.Insert(0, new AppJsonSerializerContext());
});

var app = builder.Build();

app.UseDefaultFiles();
app.UseStaticFiles();

app.MapPost("/api/register", (WorkerRegistrationRequest request) =>
{
    if (request == null || string.IsNullOrEmpty(request.Url))
    {
        return Results.BadRequest("URLがありません。");
    }
    availableWorkerUrls.Add(request.Url);
    Console.WriteLine($"[API] ワーカー登録: {request.Url}");
    return Results.Ok("登録完了");
});

app.MapPost("/api/start-job", async (JobRequest job) =>
{

    if (job == null)
    {
        return Results.BadRequest("不明な通信です");
    }

    if (job.Mode == "1")
    {
        if (string.IsNullOrEmpty(job.VideoPathRight))
        {
            return Results.BadRequest("メインの動画がありません");
        }
        if (string.IsNullOrEmpty(job.SerialNumberRight))
        {
            return Results.BadRequest("メインカメラのシリアルナンバーがありません");
        }

        Console.WriteLine($"[API] ジョブ開始: {job.VideoPathRight}");
        Console.WriteLine($"[API] 使用カメラのシリアルナンバー: {job.SerialNumberRight}");

        _ = Task.Run(() => singleProcess.SingleRunMainJobDispatcher(job.VideoPathRight, int.Parse(job.Mode), job.SerialNumberRight));
    }
    else if (job.Mode == "0")
    {
        if (string.IsNullOrEmpty(job.VideoPathRight) || string.IsNullOrEmpty(job.VideoPathLeft))
        {
            return Results.BadRequest("左右どちらかの動画がありません");
        }
        if (string.IsNullOrEmpty(job.SerialNumberRight) || string.IsNullOrEmpty(job.SerialNumberLeft))
        {
            return Results.BadRequest("左右どちらかのシリアルナンバーがありません");
        }

        Console.WriteLine($"[API] ジョブ開始: {job.VideoPathRight} | {job.VideoPathLeft}");
        Console.WriteLine($"[API] 使用カメラのシリアルナンバー: {job.SerialNumberRight} | {job.SerialNumberLeft}");

        _ = Task.Run(() => multiProcess.MultiRunMainJobDispatcher(job.VideoPathLeft, job.VideoPathRight, job.SerialNumberRight, job.SerialNumberRight, int.Parse(job.Mode)));
    }

    return Results.Ok("ジョブを開始しました。");
});

Console.WriteLine("[Server] マスターサーバーを http://localhost:5000 で起動します。");
Console.WriteLine("[Server] ブラウザで http://localhost:5000 を開いてください。");
app.Run("http://*:5000");

[JsonSerializable(typeof(WorkerRegistrationRequest))]
[JsonSerializable(typeof(JobRequest))]
public partial class AppJsonSerializerContext : JsonSerializerContext
{
}

public class WorkerRegistrationRequest
{
    public string? Url { get; set; }
}
public class JobRequest
{
    public string? VideoPathLeft        { get; set; } // ← キー名を JavaScript と一致させる
    public string? VideoPathRight       { get; set; } // ← キー名を JavaScript と一致させる
    public string? SerialNumberRight    { get; set; }
    public string? SerialNumberLeft     { get; set; }
    public string? Mode                 { get; set; }
}