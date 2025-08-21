-- 📊 完整的 CRM + 知識庫 + 自學習系統
-- 設計日期: 2025-08-18
-- 用途: LINE餐廳機器人智能客戶管理

-- ===================================
-- 1. 客戶資料表 (CRM核心)
-- ===================================
CREATE TABLE IF NOT EXISTS customers (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    line_user_id VARCHAR(255) NOT NULL UNIQUE,
    email VARCHAR(255),
    phone VARCHAR(20),
    name VARCHAR(100),
    
    -- VIP會員系統
    is_vip BOOLEAN DEFAULT false,
    vip_level INTEGER DEFAULT 0, -- 0=一般, 1=銅卡, 2=銀卡, 3=金卡, 4=鑽石
    vip_points INTEGER DEFAULT 0,
    vip_start_date TIMESTAMP WITH TIME ZONE,
    
    -- 客戶偏好
    preferred_language VARCHAR(10) DEFAULT 'zh-TW',
    communication_style VARCHAR(50) DEFAULT 'friendly', -- friendly, formal, casual
    preferred_contact_time VARCHAR(50), -- morning, afternoon, evening
    
    -- 餐廳相關偏好
    favorite_dishes TEXT[], -- 喜愛餐點
    dietary_restrictions TEXT[], -- 飲食限制：vegetarian, halal, no-spicy
    usual_party_size INTEGER DEFAULT 2, -- 常見用餐人數
    preferred_seating VARCHAR(50), -- window, quiet, bar
    
    -- 統計資料
    total_orders INTEGER DEFAULT 0,
    total_spent DECIMAL(10,2) DEFAULT 0.00,
    average_order_value DECIMAL(8,2) DEFAULT 0.00,
    last_order_date TIMESTAMP WITH TIME ZONE,
    first_visit_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 行為分析
    total_interactions INTEGER DEFAULT 0,
    avg_response_satisfaction DECIMAL(3,2) DEFAULT 0.00,
    last_interaction TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 系統欄位
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true,
    notes TEXT
);

-- 客戶資料索引
CREATE INDEX IF NOT EXISTS idx_customers_line_user_id ON customers(line_user_id);
CREATE INDEX IF NOT EXISTS idx_customers_vip ON customers(is_vip, vip_level);
CREATE INDEX IF NOT EXISTS idx_customers_email ON customers(email);
CREATE INDEX IF NOT EXISTS idx_customers_last_interaction ON customers(last_interaction);

-- ===================================
-- 2. 知識庫表 (取代Google Sheets)
-- ===================================
CREATE TABLE IF NOT EXISTS knowledge_base (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    -- 分類系統
    category VARCHAR(100) NOT NULL, -- menu, hours, reservation, delivery, promotion
    subcategory VARCHAR(100), -- appetizers, main-course, desserts, etc.
    
    -- 核心內容
    question TEXT NOT NULL,
    answer TEXT NOT NULL,
    keywords TEXT[] NOT NULL, -- 搜索關鍵字
    
    -- 智能匹配
    intent_type VARCHAR(50), -- greeting, inquiry, complaint, compliment
    confidence_threshold DECIMAL(3,2) DEFAULT 0.8,
    
    -- 內容管理
    content_type VARCHAR(50) DEFAULT 'text', -- text, image, video, link
    media_url TEXT, -- 圖片或影片連結
    external_link TEXT, -- 外部連結
    
    -- 多語言支援
    language VARCHAR(10) DEFAULT 'zh-TW',
    translations JSONB, -- 其他語言翻譯
    
    -- 使用統計
    usage_count INTEGER DEFAULT 0,
    success_rate DECIMAL(3,2) DEFAULT 1.0,
    last_used TIMESTAMP WITH TIME ZONE,
    
    -- 動態更新
    is_active BOOLEAN DEFAULT true,
    auto_generated BOOLEAN DEFAULT false, -- 是否為AI自動生成
    needs_review BOOLEAN DEFAULT false,
    
    -- 來源追蹤
    source VARCHAR(100) DEFAULT 'manual', -- manual, google-sheets, ai-learned
    source_reference TEXT,
    
    -- 系統欄位
    created_by VARCHAR(100) DEFAULT 'system',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 版本控制
    version INTEGER DEFAULT 1,
    previous_version_id UUID REFERENCES knowledge_base(id)
);

-- 知識庫索引
CREATE INDEX IF NOT EXISTS idx_knowledge_category ON knowledge_base(category, subcategory);
CREATE INDEX IF NOT EXISTS idx_knowledge_keywords ON knowledge_base USING GIN(keywords);
CREATE INDEX IF NOT EXISTS idx_knowledge_active ON knowledge_base(is_active);
CREATE INDEX IF NOT EXISTS idx_knowledge_language ON knowledge_base(language);
CREATE INDEX IF NOT EXISTS idx_knowledge_usage ON knowledge_base(usage_count DESC);

-- 全文搜索索引
CREATE INDEX IF NOT EXISTS idx_knowledge_fts ON knowledge_base USING GIN(
    to_tsvector('chinese', question || ' ' || answer || ' ' || array_to_string(keywords, ' '))
);

-- ===================================
-- 3. 客戶對話歷史表 (增強版)
-- ===================================
CREATE TABLE IF NOT EXISTS customer_conversations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
    line_user_id VARCHAR(255) NOT NULL, -- 冗余，方便查詢
    
    -- 對話內容
    message_id VARCHAR(255) NOT NULL UNIQUE,
    user_message TEXT NOT NULL,
    bot_response TEXT,
    
    -- 智能分析
    detected_intent VARCHAR(100),
    confidence_score DECIMAL(3,2),
    sentiment VARCHAR(20), -- positive, negative, neutral
    urgency_level INTEGER DEFAULT 1, -- 1=低, 2=中, 3=高, 4=緊急
    
    -- 知識庫關聯
    matched_knowledge_id UUID REFERENCES knowledge_base(id),
    knowledge_confidence DECIMAL(3,2),
    
    -- 客服質量
    response_time_ms INTEGER,
    customer_satisfaction INTEGER, -- 1-5分
    requires_human_followup BOOLEAN DEFAULT false,
    
    -- 業務分析
    has_business_intent BOOLEAN DEFAULT false, -- 是否包含業務意圖
    extracted_info JSONB, -- 提取的結構化信息：姓名、電話、日期等
    
    -- 系統記錄
    conversation_session_id VARCHAR(255),
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 對話歷史索引
CREATE INDEX IF NOT EXISTS idx_conversations_customer ON customer_conversations(customer_id);
CREATE INDEX IF NOT EXISTS idx_conversations_line_user ON customer_conversations(line_user_id);
CREATE INDEX IF NOT EXISTS idx_conversations_intent ON customer_conversations(detected_intent);
CREATE INDEX IF NOT EXISTS idx_conversations_date ON customer_conversations(DATE(created_at));
CREATE INDEX IF NOT EXISTS idx_conversations_satisfaction ON customer_conversations(customer_satisfaction);

-- ===================================
-- 4. 智能學習模式表 (升級版)
-- ===================================
CREATE TABLE IF NOT EXISTS ai_learning_patterns (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    -- 模式分類
    pattern_category VARCHAR(100) NOT NULL, -- customer-behavior, response-optimization, intent-recognition
    pattern_type VARCHAR(100) NOT NULL, -- frequent-question, vip-preference, time-pattern
    
    -- 模式內容
    pattern_name VARCHAR(200) NOT NULL,
    pattern_description TEXT NOT NULL,
    pattern_data JSONB NOT NULL, -- 結構化模式數據
    
    -- 適用範圍
    applies_to_customer_id UUID REFERENCES customers(id), -- 特定客戶模式
    applies_to_vip_level INTEGER, -- 特定VIP等級
    applies_to_all BOOLEAN DEFAULT false, -- 全局模式
    
    -- 效果評估
    confidence_score DECIMAL(3,2) NOT NULL DEFAULT 0.5,
    success_rate DECIMAL(3,2) DEFAULT 0.5,
    usage_count INTEGER DEFAULT 0,
    positive_feedback INTEGER DEFAULT 0,
    negative_feedback INTEGER DEFAULT 0,
    
    -- 生命週期管理
    is_active BOOLEAN DEFAULT true,
    auto_deactivate_date TIMESTAMP WITH TIME ZONE,
    last_validated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 學習來源
    learned_from_conversations INTEGER DEFAULT 0, -- 學習來源對話數量
    sample_conversation_ids UUID[],
    
    -- 系統管理
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by_ai BOOLEAN DEFAULT true
);

-- AI學習模式索引
CREATE INDEX IF NOT EXISTS idx_ai_patterns_category ON ai_learning_patterns(pattern_category, pattern_type);
CREATE INDEX IF NOT EXISTS idx_ai_patterns_customer ON ai_learning_patterns(applies_to_customer_id);
CREATE INDEX IF NOT EXISTS idx_ai_patterns_confidence ON ai_learning_patterns(confidence_score DESC);
CREATE INDEX IF NOT EXISTS idx_ai_patterns_active ON ai_learning_patterns(is_active);

-- ===================================
-- 5. 系統分析數據表
-- ===================================
CREATE TABLE IF NOT EXISTS system_analytics (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    -- 分析類型
    metric_type VARCHAR(100) NOT NULL, -- conversation-quality, knowledge-usage, customer-satisfaction
    metric_name VARCHAR(100) NOT NULL,
    
    -- 時間維度
    date_recorded DATE NOT NULL DEFAULT CURRENT_DATE,
    hour_recorded INTEGER, -- 0-23, 用於小時分析
    
    -- 分析數據
    metric_value DECIMAL(10,2) NOT NULL,
    metric_count INTEGER DEFAULT 1,
    additional_data JSONB,
    
    -- 關聯資訊
    customer_id UUID REFERENCES customers(id),
    knowledge_id UUID REFERENCES knowledge_base(id),
    conversation_id UUID REFERENCES customer_conversations(id),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 系統分析索引
CREATE INDEX IF NOT EXISTS idx_analytics_type ON system_analytics(metric_type, metric_name);
CREATE INDEX IF NOT EXISTS idx_analytics_date ON system_analytics(date_recorded);
CREATE INDEX IF NOT EXISTS idx_analytics_customer ON system_analytics(customer_id);

-- ===================================
-- 6. 觸發器和自動更新函數
-- ===================================

-- 更新客戶最後互動時間
CREATE OR REPLACE FUNCTION update_customer_last_interaction()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE customers 
    SET 
        last_interaction = NEW.created_at,
        total_interactions = total_interactions + 1,
        updated_at = NOW()
    WHERE line_user_id = NEW.line_user_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_customer_interaction
    AFTER INSERT ON customer_conversations
    FOR EACH ROW EXECUTE FUNCTION update_customer_last_interaction();

-- 更新知識庫使用統計
CREATE OR REPLACE FUNCTION update_knowledge_usage()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.matched_knowledge_id IS NOT NULL THEN
        UPDATE knowledge_base 
        SET 
            usage_count = usage_count + 1,
            last_used = NEW.created_at,
            updated_at = NOW()
        WHERE id = NEW.matched_knowledge_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_knowledge_usage
    AFTER INSERT ON customer_conversations
    FOR EACH ROW EXECUTE FUNCTION update_knowledge_usage();

-- 自動更新時間戳
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_customers_updated_at 
    BEFORE UPDATE ON customers 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_knowledge_updated_at 
    BEFORE UPDATE ON knowledge_base 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ai_patterns_updated_at 
    BEFORE UPDATE ON ai_learning_patterns 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ===================================
-- 7. 實用視圖
-- ===================================

-- VIP客戶概覽
CREATE OR REPLACE VIEW vip_customers_overview AS
SELECT 
    c.*,
    COUNT(cc.id) as total_messages,
    AVG(cc.customer_satisfaction) as avg_satisfaction,
    MAX(cc.created_at) as last_message_date
FROM customers c
LEFT JOIN customer_conversations cc ON c.id = cc.customer_id
WHERE c.is_vip = true
GROUP BY c.id
ORDER BY c.vip_level DESC, c.vip_points DESC;

-- 知識庫使用排行
CREATE OR REPLACE VIEW knowledge_usage_ranking AS
SELECT 
    kb.*,
    COUNT(cc.id) as times_used,
    AVG(cc.confidence_score) as avg_confidence,
    MAX(cc.created_at) as last_used_date
FROM knowledge_base kb
LEFT JOIN customer_conversations cc ON kb.id = cc.matched_knowledge_id
WHERE kb.is_active = true
GROUP BY kb.id
ORDER BY times_used DESC, kb.success_rate DESC;

-- 每日客戶活動統計
CREATE OR REPLACE VIEW daily_customer_activity AS
SELECT 
    DATE(cc.created_at) as activity_date,
    COUNT(DISTINCT cc.customer_id) as unique_customers,
    COUNT(cc.id) as total_messages,
    AVG(cc.customer_satisfaction) as avg_satisfaction,
    COUNT(*) FILTER (WHERE cc.requires_human_followup = true) as escalated_conversations
FROM customer_conversations cc
GROUP BY DATE(cc.created_at)
ORDER BY activity_date DESC;

-- ===================================
-- 8. 初始化基礎數據
-- ===================================

-- 插入基礎知識庫資料
INSERT INTO knowledge_base (category, subcategory, question, answer, keywords, intent_type) VALUES
('restaurant_info', 'hours', '營業時間是什麼時候？', '小明的餐廳營業時間為週一至週日 11:00 - 22:00', ARRAY['營業', '時間', '開店', '關店', 'hours'], 'inquiry'),
('restaurant_info', 'location', '餐廳在哪裡？', '小明的餐廳位於台北市中山區中山路 123 號，搭乘捷運中山站1號出口步行3分鐘即可到達', ARRAY['地址', '位置', '在哪', '怎麼去', 'location'], 'inquiry'),
('restaurant_info', 'contact', '聯絡電話多少？', '您可以撥打 02-1234-5678 聯絡小明的餐廳，或透過LINE直接與我們對話', ARRAY['電話', '聯絡', '預約', 'phone'], 'inquiry'),
('service', 'delivery', '有外送服務嗎？', '是的！我們提供外送服務，配送範圍為餐廳周邊5公里內，也可透過Uber Eats和Foodpanda訂購', ARRAY['外送', '送餐', '配送', 'delivery'], 'inquiry'),
('service', 'payment', '接受什麼付款方式？', '我們接受現金、信用卡、Line Pay、Apple Pay等多種支付方式，讓您用餐更便利', ARRAY['付款', '支付', '刷卡', '現金', 'payment'], 'inquiry'),
('menu', 'signature', '有什麼招牌菜？', '我們的招牌菜包括：經典牛肉麵、四川麻辣火鍋、蜜汁烤雞，每道都是客人最愛的必點料理！', ARRAY['招牌', '推薦', '特色', '必點'], 'inquiry'),
('reservation', 'process', '如何訂位？', '訂位很簡單！請告訴我您的：1.用餐日期 2.用餐時間 3.用餐人數 4.您的姓名 5.聯絡電話，我會立即為您安排', ARRAY['訂位', '預約', '訂桌', 'reservation'], 'inquiry'),
('vip', 'benefits', 'VIP會員有什麼好處？', 'VIP會員享有：9折優惠、優先訂位、生日優惠、專屬客服，還可累積點數兌換免費餐點！', ARRAY['VIP', '會員', '優惠', 'benefits'], 'inquiry');

-- 創建範例VIP客戶
INSERT INTO customers (line_user_id, name, email, is_vip, vip_level, vip_points, total_orders, total_spent) VALUES
('demo_vip_user_001', '王小明', 'wang@example.com', true, 3, 2500, 15, 4500.00),
('demo_regular_user_001', '李小華', 'li@example.com', false, 0, 0, 3, 890.00);

-- 完成提示
SELECT '🎉 CRM + 知識庫系統建置完成！' as status,
       '📊 包含客戶管理、VIP系統、知識庫、AI學習模式' as features,
       '🚀 可開始部署智能餐廳機器人' as next_step;