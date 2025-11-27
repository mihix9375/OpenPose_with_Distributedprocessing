using Google.Protobuf;
using Grpc.Net.Client;
using Grpc.Core;
using OpenCvSharp;
using OpenPoseStream;
using System.Collections.Concurrent;

namespace OpenPoseServer
{
    public class SingleProcess
    {
        AvailableWorkers availableWorkers = new AvailableWorkers();
        public static bool issuccess { get; private set; } = false;

        public async Task SingleRunMainJobDispatcher(string videoPath, int mode, string serial)
        {
            Console.WriteLine($"[Main] 動画ストリーミング処理開始...");
            Directory.CreateDirectory(@"./json");

            using var videoRight = new VideoCapture(videoPath);

            if (!videoRight.IsOpened())
            {
                Console.WriteLine("[Main] エラー: 左右どちらかの動画が開けません。");
                return;
            }

            using var frame = new Mat();

            int frameCount = 1;


            while (true)
            {

                bool retRight = videoRight.Read(frame);

                if (!retRight || frame.Empty())
                {
                    break;
                }

                byte[] imageData = frame.ToBytes(".jpg");


                Console.WriteLine("[Main] 空きワーカー待ち...");
                string? workerUrl = null;
                while (workerUrl is null)
                {
                    if (!(availableWorkers.availableWorkersURL is null))
                    {
                        workerUrl = availableWorkers.availableWorkersURL.First();
                        availableWorkers.ControlWorkers(workerUrl, "Remove");
                    }

                    await Task.Delay(100);
                }

                Console.WriteLine($"[Main] ワーカー {workerUrl} にフレーム {frameCount} (L/R) を送信。");
                _ = SingleSendFrameToWorkerAsync(workerUrl, imageData, frameCount, mode, serial);

                frameCount++;
            }

            Console.WriteLine($"[Main] 全 {frameCount - 1} フレームの送信完了。");
        }


        private async Task SingleSendFrameToWorkerAsync(string workerUrl, byte[] imageData, int frameId, int mode, string serial)
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
                    ImageRight = ByteString.CopyFrom(imageData),
                    SerialRight = serial,
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
                _ = SingleSendFrameToWorkerAsync(workerUrl, imageData, frameId, mode, serial);
            }
        }
    }
}
