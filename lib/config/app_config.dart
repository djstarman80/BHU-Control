class AppConfig {
  // CORS Proxy para Web
  static const String corsProxy = 'https://mi-cors-proxy.bhu-cors-proxy.workers.dev';

  // Valores monetarios por defecto
  static const double defaultUiValue = 6.4296;
  static const double defaultUrValue = 1847.96;
  static const double defaultDolarValue = 39.70;

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 8);
  static const Duration bcuFallbackTimeout = Duration(seconds: 4);
  static const Duration dbTimeout = Duration(seconds: 30);

  // URLs de APIs
  static const String bcuApiUrl =
      'https://cotizaciones.bcu.gub.uy/wscotizaciones/servlet/awsbcucotizaciones';
  static const String dolarApiUrl =
      '$corsProxy/?url=https://uy.dolarapi.com/v1/cotizaciones/ui';
  static const String dolarVentaApiUrl =
      '$corsProxy/?url=https://uy.dolarapi.com/v1/cotizaciones/usd';
  static const String brouCotizacionesUrl =
      'https://www.brou.com.uy/c/portal/render_portlet?p_l_id=20593&p_p_id=cotizacionfull_WAR_broutmfportlet_INSTANCE_otHfewh1klyS';

  // Base de datos
  static const String dbName = 'bhu_control.db';
  static const int dbVersion = 1;

  // SOAP Action para BCU
  static const String bcuSoapAction = 'Cotiza/wsbcucotizaciones.Execute';

  // Códigos de moneda BCU
  static const String monedaUi = '9800';
  static const String monedaUr = '9900';

  // Modos de fuente disponibles
  static const List<String> availableModes = [
    'AUTO',
    'BROU',
    'BCU',
    'DolarApi',
    'MANUAL'
  ];

  // Configuración por moneda
  static const Map<String, MonedaSourceConfig> monedaConfigs = {
    'USD': MonedaSourceConfig(
      moneda: 'USD',
      webSources: ['DolarApi', 'BROU'],
      defaultValue: 39.70,
      availableModes: ['AUTO', 'DolarApi', 'BROU', 'MANUAL'],
    ),
    'UI': MonedaSourceConfig(
      moneda: 'UI',
      webSources: ['DolarApi', 'BCU', 'BROU'],
      defaultValue: 6.4296,
      availableModes: ['AUTO', 'DolarApi', 'BCU', 'BROU', 'MANUAL'],
    ),
    'UR': MonedaSourceConfig(
      moneda: 'UR',
      webSources: ['BCU'],
      defaultValue: 1847.96,
      availableModes: ['AUTO', 'BCU', 'MANUAL'],
    ),
  };
}

class MonedaSourceConfig {
  final String moneda;
  final List<String> webSources;
  final double defaultValue;
  final List<String> availableModes;

  const MonedaSourceConfig({
    required this.moneda,
    required this.webSources,
    required this.defaultValue,
    required this.availableModes,
  });
}
