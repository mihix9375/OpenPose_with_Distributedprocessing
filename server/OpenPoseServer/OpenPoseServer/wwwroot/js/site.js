// "startButton" というIDのボタンがクリックされたら実行
document.getElementById('startButton').addEventListener('click', async () => {

    // "videoPathInput" というIDのテキストボックスから値を取得
    const pathright = document.getElementById('rightvideoPathInput').value;
    const pathleft = document.getElementById('leftvideoPathInput').value;
    const serialright = document.getElementById('serialNumberRight').value;
    const serialleft = document.getElementById('serialNumberLeft').value;
    const mode = document.getElementById('mode').value;

    console.log(`サーバーに処理を依頼します: ${pathright},  ${pathleft}`);

    try {
        // C#サーバーの /api/start-job に対して、POSTリクエストを送信
        const response = await fetch('/api/start-job', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                VideoPathLeft: pathleft,
                VideoPathRight: pathright,
                SerialNumberRight: serialright,
                SerialNumberLeft: serialleft,
                Mode: mode
            })
        });

        const result = await response.text();
        alert(`サーバーの応答: ${result}`);

    } catch (error) {
        console.error('エラー:', error);
        alert('サーバーへのリクエストに失敗しました。');
    }
});