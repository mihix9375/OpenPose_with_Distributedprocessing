using Google.Protobuf;
using Grpc.Net.Client;
using Grpc.Core;
using OpenCvSharp;
using OpenPoseStream;
using System.Collections.Concurrent;

namespace OpenPoseServer
{
    public class MultiProcess
    {
        AvailableWorkers availableWorkers = new AvailableWorkers();

        public async Task MultiRunMainJobDispatcher(string videoPathLeft, string videoPathRight, string serialRight, string serialLeft, int mode)
        {
            Console.WriteLine($"[Main] 動画ストリーミング処理開始...");
            Directory.CreateDirectory(@"./json");

            using var videoLeft = new VideoCapture(videoPathLeft);
            using var videoRight = new VideoCapture(videoPathRight);

            if (!videoLeft.IsOpened() || !videoRight.IsOpened())
            {
                Console.WriteLine("[Main] エラー: 左右どちらかの動画が開けません。");
                return;
            }

            using var frameLeft = new Mat();
            using var frameRight = new Mat();

            int frameCount = 1;


            while (true)
            {

                bool retLeft = videoLeft.Read(frameLeft);
                bool retRight = videoRight.Read(frameRight);

                if (!retLeft || !retRight || frameLeft.Empty() || frameRight.Empty())
                {
                    break;
                }

                byte[] imageDataLeft = frameLeft.ToBytes(".jpg");
                byte[] imageDataRight = frameRight.ToBytes(".jpg");

                
                Console.WriteLine("[Main] 空きワーカー待ち...");
                string? workerUrl = null;
                while (workerUrl is null)
                {
                    if (!(availableWorkers.availableWorkersURL is null || availableWorkers.availableWorkersURL.First() is null))
                    {
                        workerUrl = availableWorkers.availableWorkersURL.First();
                        availableWorkers.ControlWorkers(workerUrl, "Remove");
                    }

                    await Task.Delay(100);
                }

                Console.WriteLine($"[Main] ワーカー {workerUrl} にフレーム {frameCount} (L/R) を送信。");
                _ = MultiSendFrameToWorkerAsync(workerUrl, imageDataLeft, imageDataRight, frameCount, serialRight, videoPathLeft, mode);

                frameCount++;
            }

            Console.WriteLine($"[Main] 全 {frameCount - 1} フレームの送信完了。");
        }

        private async Task MultiSendFrameToWorkerAsync(string workerUrl, byte[] imageDataLeft, byte[] imageDataRight, int frameId, string serialRight, string serialLeft, int mode)
        {
            var channel = GrpcChannel.ForAddress(workerUrl);
            var client = new OpenPoseStreamer.OpenPoseStreamerClient(channel);
            using var call = client.ProcessStream();
            try
            {
                await call.RequestStream.WriteAsync(new FrameRequest
                {
                    FrameId = frameId,
                    Mode = mode,
                    ImageRight = ByteString.CopyFrom(imageDataRight),
                    SerialRight = serialRight,
                    ImageLeft = ByteString.CopyFrom(imageDataLeft),
                    SerialLeft = serialLeft,
                });

                if (await call.ResponseStream.MoveNext())
                {
                    var result = call.ResponseStream.Current;
                    string jsonResponse = result.JsonData;

                    string jsonPath = Path.Combine("./json", $"{frameId}.json");
                    await System.IO.File.WriteAllTextAsync(jsonPath, jsonResponse);

                    availableWorkers.ControlWorkers(workerUrl, "Add");
                }
                else
                {
                    throw new Exception("[Warn] サーバーからレスポンスがありませんでした。");
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[Worker {workerUrl}] 処理失敗: {ex.Message} (フレーム: {frameId})");
                Console.WriteLine("[Info] 2秒後、再試行します");
                await Task.Delay(2000);
                _ = MultiSendFrameToWorkerAsync(workerUrl, imageDataLeft, imageDataRight, frameId, serialRight, serialLeft, mode);
            }
        }
    }
}
