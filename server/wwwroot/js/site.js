// "startButton" というIDのボタンがクリックされたら実行
document.getElementById('startButton').addEventListener('click', async () => {

    // "videoPathInput" というIDのテキストボックスから値を取得
    const path = document.getElementById('videoPathInput').value;

    console.log(`サーバーに処理を依頼します: ${path}`);

    try {
        // C#サーバーの /api/start-job に対して、POSTリクエストを送信
        const response = await fetch('/api/start-job', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ videoPath: path }) // C#側の JobRequest クラスに合うようにJSONで送る
        });

        const result = await response.text();
        alert(`サーバーの応答: ${result}`);

    } catch (error) {
        console.error('エラー:', error);
        alert('サーバーへのリクエストに失敗しました。');
    }
});