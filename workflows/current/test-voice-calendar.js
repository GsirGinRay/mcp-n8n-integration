// 語音轉日曆工作流測試腳本
// 使用 Node.js 測試 n8n 語音日曆工作流

const axios = require('axios');
const fs = require('fs');

// 配置設置
const config = {
  n8nWebhookUrl: 'http://localhost:5678/webhook/voice-calendar', // 替換為您的 n8n 實例 URL
  testAudioFile: './test-audio-samples/test-voice.wav', // 測試音檔路徑
  testCases: [
    {
      name: '明天下午會議測試',
      text: '明天下午3點開會討論專案進度',
      expectedDate: getTomorrowDate(),
      expectedTime: '15:00'
    },
    {
      name: '今天晚餐測試', 
      text: '今天晚上7點和朋友聚餐',
      expectedDate: getTodayDate(),
      expectedTime: '19:00'
    },
    {
      name: '下週面試測試',
      text: '下週一上午9點面試新員工',
      expectedDate: getNextMondayDate(),
      expectedTime: '09:00'
    }
  ]
};

// 輔助函數
function getTodayDate() {
  return new Date().toISOString().split('T')[0];
}

function getTomorrowDate() {
  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);
  return tomorrow.toISOString().split('T')[0];
}

function getNextMondayDate() {
  const today = new Date();
  const daysUntilMonday = (8 - today.getDay()) % 7 || 7;
  const nextMonday = new Date(today.getTime() + daysUntilMonday * 24 * 60 * 60 * 1000);
  return nextMonday.toISOString().split('T')[0];
}

// 模擬語音檔案轉 Base64
function encodeAudioToBase64(filePath) {
  try {
    const audioBuffer = fs.readFileSync(filePath);
    return audioBuffer.toString('base64');
  } catch (error) {
    console.log('📁 測試音檔不存在，使用模擬數據');
    return 'mock-base64-audio-data';
  }
}

// 測試單個案例
async function testVoiceCalendar(testCase) {
  console.log(`\n🧪 測試案例: ${testCase.name}`);
  console.log(`📝 測試語音: "${testCase.text}"`);
  
  try {
    // 準備測試數據
    const testData = {
      audioFile: encodeAudioToBase64(config.testAudioFile),
      // 模擬語音轉文字結果（實際環境中會由 Google Speech API 處理）
      mockTranscription: testCase.text
    };

    // 發送請求到 n8n webhook
    const response = await axios.post(config.n8nWebhookUrl, testData, {
      headers: {
        'Content-Type': 'application/json'
      },
      timeout: 30000 // 30秒超時
    });

    // 檢查回應
    if (response.data.success) {
      console.log('✅ 測試成功!');
      console.log(`📅 事件ID: ${response.data.eventId}`);
      console.log(`📝 事件標題: ${response.data.summary}`);
      console.log(`⏰ 開始時間: ${response.data.startTime}`);
      
      // 驗證結果
      const actualDate = response.data.startTime.split('T')[0];
      const actualTime = response.data.startTime.split('T')[1].substring(0, 5);
      
      if (actualDate === testCase.expectedDate && actualTime === testCase.expectedTime) {
        console.log('✅ 日期時間解析正確');
      } else {
        console.log('⚠️ 日期時間解析可能有誤');
        console.log(`   預期: ${testCase.expectedDate} ${testCase.expectedTime}`);
        console.log(`   實際: ${actualDate} ${actualTime}`);
      }
    } else {
      console.log('❌ 測試失敗');
      console.log(`錯誤: ${response.data.message}`);
    }

  } catch (error) {
    console.log('❌ 測試執行錯誤');
    if (error.response) {
      console.log(`HTTP狀態: ${error.response.status}`);
      console.log(`錯誤回應: ${JSON.stringify(error.response.data, null, 2)}`);
    } else if (error.request) {
      console.log('無法連接到 n8n 實例，請檢查 URL 和網路連接');
    } else {
      console.log(`錯誤詳情: ${error.message}`);
    }
  }
}

// 執行所有測試
async function runAllTests() {
  console.log('🚀 開始執行語音轉日曆工作流測試');
  console.log(`🌐 目標 URL: ${config.n8nWebhookUrl}`);
  console.log('=' * 50);

  // 檢查 n8n 連接
  try {
    await axios.get(config.n8nWebhookUrl.replace('/webhook/voice-calendar', '/healthz'), {
      timeout: 5000
    });
    console.log('✅ n8n 實例連接正常');
  } catch (error) {
    console.log('⚠️ 無法驗證 n8n 連接，繼續測試...');
  }

  // 執行所有測試案例
  for (const testCase of config.testCases) {
    await testVoiceCalendar(testCase);
    await new Promise(resolve => setTimeout(resolve, 2000)); // 等待2秒
  }

  console.log('\n🏁 所有測試執行完畢');
  console.log('\n📋 測試報告總結:');
  console.log('- 請檢查您的 Google Calendar 是否有新增的事件');
  console.log('- 確認事件的日期、時間和標題是否正確');
  console.log('- 如有錯誤，請檢查 n8n 工作流的執行日誌');
}

// 單獨測試自然語言處理邏輯
function testTextParsing() {
  console.log('\n🔍 測試文字解析邏輯');
  
  const testTexts = [
    '明天下午3點開會討論專案進度',
    '今天晚上7點和朋友聚餐', 
    '下週一上午9點面試新員工',
    '3月15日下午2點醫生預約'
  ];

  testTexts.forEach(text => {
    console.log(`\n📝 測試文字: "${text}"`);
    
    // 模擬工作流中的解析邏輯
    const patterns = {
      date: /(今天|明天|後天|下週|([0-9]{1,2}月[0-9]{1,2}日)|([0-9]{4}年[0-9]{1,2}月[0-9]{1,2}日))/g,
      time: /(上午|下午|早上|晚上)?([0-9]{1,2})[:點]?([0-9]{1,2}分?)?/g,
      event: /(會議|開會|約會|聚餐|運動|健身|上課|工作|面試)/g
    };

    const dateMatch = text.match(patterns.date);
    const timeMatch = text.match(patterns.time);
    const eventMatch = text.match(patterns.event);

    console.log(`📅 日期匹配: ${dateMatch ? dateMatch[0] : '無'}`);
    console.log(`⏰ 時間匹配: ${timeMatch ? timeMatch[0] : '無'}`);
    console.log(`📋 事件匹配: ${eventMatch ? eventMatch[0] : '無'}`);
  });
}

// 主函數
async function main() {
  const args = process.argv.slice(2);
  
  if (args.includes('--parse-only')) {
    testTextParsing();
  } else if (args.includes('--help')) {
    console.log(`
語音轉日曆工作流測試工具

使用方式:
  node test-voice-calendar.js          # 執行完整測試
  node test-voice-calendar.js --parse-only   # 僅測試文字解析
  node test-voice-calendar.js --help         # 顯示幫助

設置:
  1. 確保 n8n 實例正在運行
  2. 更新 config.n8nWebhookUrl 為正確的 webhook URL
  3. 確保已配置 Google Speech API 和 Calendar API 憑證
  4. 可選: 放置測試音檔到 ./test-audio-samples/test-voice.wav
    `);
  } else {
    await runAllTests();
  }
}

// 執行測試
if (require.main === module) {
  main().catch(console.error);
}

module.exports = {
  testVoiceCalendar,
  testTextParsing,
  config
};