# デバッグ コンテナーをカスタマイズする方法と、Visual Studio がこの Dockerfile を使用してより高速なデバッグのためにイメージをビルドする方法については、https://aka.ms/customizecontainer をご覧ください。

# コンテナーをビルドまたは実行するホスト コンピューターのオペレーティング システムによっては、FROM ステートメントで指定されたイメージを変更する必要がある場合があります。
# 詳細については、https://aka.ms/containercompat を参照してください

# このステージは、VS から高速モードで実行するときに使用されます (デバッグ構成の既定値)
FROM mcr.microsoft.com/dotnet/aspnet:8.0-nanoserver-1809 AS base
WORKDIR /app
EXPOSE 8080


# このステージは、サービス プロジェクトのビルドに使用されます
FROM mcr.microsoft.com/dotnet/sdk:8.0-windowsservercore-ltsc2019 AS build
# Visual Studio Build Tools をインストールしてください。AOT パブリッシュには必要です。
# 注意: Visual Studio Build Tools を使用するには、有効な Visual Studio ライセンスが必要です。
RUN curl -SL --output vs_buildtools.exe https://aka.ms/vs/17/release/vs_buildtools.exe
RUN vs_buildtools.exe --installPath C:\BuildTools --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 Microsoft.VisualStudio.Component.Windows10SDK.19041 --quiet --wait --norestart --nocache
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
COPY ["OpenPoseServer/OpenPoseServer.csproj", "OpenPoseServer/"]
RUN dotnet restore "./OpenPoseServer/OpenPoseServer.csproj"
COPY . .
WORKDIR "/src/OpenPoseServer"
RUN dotnet build "./OpenPoseServer.csproj" -c %BUILD_CONFIGURATION% -o /app/build

# このステージは、最終ステージにコピーするサービス プロジェクトを公開するために使用されます
FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "./OpenPoseServer.csproj" -c %BUILD_CONFIGURATION% -o /app/publish /p:UseAppHost=true

# このステージは、運用環境または VS から通常モードで実行している場合に使用されます (デバッグ構成を使用しない場合の既定)
FROM mcr.microsoft.com/dotnet/runtime:8.0-nanoserver-1809 AS final
WORKDIR /app
EXPOSE 8080
COPY --from=publish /app/publish .
ENTRYPOINT ["OpenPoseServer.exe"]