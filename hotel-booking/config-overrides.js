module.exports = function override(config, env) {
    // 'source-map-loader'를 사용하는 모든 규칙을 필터링합니다.
    config.module.rules = config.module.rules.filter(
        rule => !(rule.enforce === 'pre' && rule.use && rule.use[0].loader === 'source-map-loader')
    );
    return config;
};
