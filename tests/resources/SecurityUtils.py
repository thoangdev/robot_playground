"""
Security testing utilities for Robot Framework tests
Provides OWASP ZAP integration for security testing
"""

import os
import time
import requests
from robot.api.deco import keyword
from robot.libraries.BuiltIn import BuiltIn


class SecurityUtils:
    """Custom security library for Robot Framework with OWASP ZAP integration"""
    
    ROBOT_LIBRARY_SCOPE = 'GLOBAL'
    
    def __init__(self):
        self.builtin = BuiltIn()
        self.zap_proxy = None
        self.zap_api_key = None
        self.zap_enabled = False
        self._setup_zap_proxy()
    
    def _setup_zap_proxy(self):
        """Initialize ZAP proxy settings from environment variables"""
        try:
            zap_proxy_url = os.getenv('ZAP_PROXY', '').strip()
            self.zap_api_key = os.getenv('ZAP_API_KEY', '').strip()
            
            if zap_proxy_url:
                self.zap_proxy = zap_proxy_url
                self.zap_enabled = True
                self.builtin.log(f"ZAP Proxy enabled: {zap_proxy_url}", level='INFO')
            else:
                self.builtin.log("ZAP Proxy not configured - security testing disabled", level='INFO')
        except Exception as e:
            self.builtin.log(f"Failed to setup ZAP proxy: {str(e)}", level='WARN')
    
    @keyword
    def is_zap_proxy_enabled(self):
        """Check if ZAP proxy is enabled"""
        return self.zap_enabled
    
    @keyword
    def get_zap_proxy_settings(self):
        """Get ZAP proxy settings for browser configuration"""
        if not self.zap_enabled:
            return None
        
        try:
            # Parse proxy URL to extract host and port
            from urllib.parse import urlparse
            parsed = urlparse(self.zap_proxy)
            
            proxy_settings = {
                'http': self.zap_proxy,
                'https': self.zap_proxy,
                'host': parsed.hostname,
                'port': parsed.port or 8080
            }
            
            return proxy_settings
        except Exception as e:
            raise Exception(f"Failed to parse ZAP proxy settings: {str(e)}")
    
    @keyword
    def configure_browser_with_zap_proxy(self):
        """Configure browser to use ZAP proxy"""
        if not self.zap_enabled:
            self.builtin.log("ZAP proxy not enabled, skipping proxy configuration", level='INFO')
            return "ZAP proxy not enabled"
        
        try:
            proxy_settings = self.get_zap_proxy_settings()
            host = proxy_settings['host']
            port = proxy_settings['port']
            
            # Return proxy arguments for browser options
            proxy_args = [
                f"--proxy-server=http://{host}:{port}",
                "--ignore-certificate-errors",
                "--ignore-ssl-errors",
                "--ignore-certificate-errors-spki-list"
            ]
            
            return proxy_args
        except Exception as e:
            raise Exception(f"Failed to configure browser with ZAP proxy: {str(e)}")
    
    @keyword
    def configure_requests_with_zap_proxy(self):
        """Configure requests session to use ZAP proxy"""
        if not self.zap_enabled:
            return {}
        
        try:
            proxy_settings = self.get_zap_proxy_settings()
            proxies = {
                'http': proxy_settings['http'],
                'https': proxy_settings['https']
            }
            
            # Disable SSL verification when using proxy
            verify_ssl = False
            
            return {'proxies': proxies, 'verify': verify_ssl}
        except Exception as e:
            raise Exception(f"Failed to configure requests with ZAP proxy: {str(e)}")
    
    @keyword
    def start_zap_spider(self, target_url):
        """Start ZAP spider scan on target URL"""
        if not self.zap_enabled:
            self.builtin.log("ZAP proxy not enabled, skipping spider scan", level='WARN')
            return "ZAP proxy not enabled"
        
        try:
            zap_api_url = f"{self.zap_proxy}/JSON/spider/action/scan/"
            params = {
                'url': target_url,
                'apikey': self.zap_api_key
            }
            
            response = requests.get(zap_api_url, params=params)
            response.raise_for_status()
            
            result = response.json()
            scan_id = result.get('scan')
            
            self.builtin.log(f"ZAP spider scan started with ID: {scan_id}", level='INFO')
            return scan_id
        except Exception as e:
            raise Exception(f"Failed to start ZAP spider scan: {str(e)}")
    
    @keyword
    def wait_for_zap_spider_completion(self, scan_id, timeout=300):
        """Wait for ZAP spider scan to complete"""
        if not self.zap_enabled:
            return "ZAP proxy not enabled"
        
        try:
            zap_api_url = f"{self.zap_proxy}/JSON/spider/view/status/"
            params = {
                'scanId': scan_id,
                'apikey': self.zap_api_key
            }
            
            start_time = time.time()
            while time.time() - start_time < timeout:
                response = requests.get(zap_api_url, params=params)
                response.raise_for_status()
                
                result = response.json()
                status = result.get('status', '0')
                
                if status == '100':
                    self.builtin.log(f"ZAP spider scan {scan_id} completed", level='INFO')
                    return "Spider scan completed"
                
                self.builtin.log(f"Spider scan progress: {status}%", level='INFO')
                time.sleep(5)
            
            raise Exception(f"Spider scan {scan_id} did not complete within {timeout} seconds")
        except Exception as e:
            raise Exception(f"Failed to wait for spider scan completion: {str(e)}")
    
    @keyword
    def start_zap_active_scan(self, target_url):
        """Start ZAP active security scan"""
        if not self.zap_enabled:
            self.builtin.log("ZAP proxy not enabled, skipping active scan", level='WARN')
            return "ZAP proxy not enabled"
        
        try:
            zap_api_url = f"{self.zap_proxy}/JSON/ascan/action/scan/"
            params = {
                'url': target_url,
                'apikey': self.zap_api_key
            }
            
            response = requests.get(zap_api_url, params=params)
            response.raise_for_status()
            
            result = response.json()
            scan_id = result.get('scan')
            
            self.builtin.log(f"ZAP active scan started with ID: {scan_id}", level='INFO')
            return scan_id
        except Exception as e:
            raise Exception(f"Failed to start ZAP active scan: {str(e)}")
    
    @keyword
    def wait_for_zap_active_scan_completion(self, scan_id, timeout=600):
        """Wait for ZAP active scan to complete"""
        if not self.zap_enabled:
            return "ZAP proxy not enabled"
        
        try:
            zap_api_url = f"{self.zap_proxy}/JSON/ascan/view/status/"
            params = {
                'scanId': scan_id,
                'apikey': self.zap_api_key
            }
            
            start_time = time.time()
            while time.time() - start_time < timeout:
                response = requests.get(zap_api_url, params=params)
                response.raise_for_status()
                
                result = response.json()
                status = result.get('status', '0')
                
                if status == '100':
                    self.builtin.log(f"ZAP active scan {scan_id} completed", level='INFO')
                    return "Active scan completed"
                
                self.builtin.log(f"Active scan progress: {status}%", level='INFO')
                time.sleep(10)
            
            raise Exception(f"Active scan {scan_id} did not complete within {timeout} seconds")
        except Exception as e:
            raise Exception(f"Failed to wait for active scan completion: {str(e)}")
    
    @keyword
    def get_zap_alerts(self, base_url=None):
        """Get security alerts from ZAP"""
        if not self.zap_enabled:
            return []
        
        try:
            zap_api_url = f"{self.zap_proxy}/JSON/core/view/alerts/"
            params = {'apikey': self.zap_api_key}
            
            if base_url:
                params['baseurl'] = base_url
            
            response = requests.get(zap_api_url, params=params)
            response.raise_for_status()
            
            result = response.json()
            alerts = result.get('alerts', [])
            
            self.builtin.log(f"Retrieved {len(alerts)} security alerts from ZAP", level='INFO')
            return alerts
        except Exception as e:
            raise Exception(f"Failed to get ZAP alerts: {str(e)}")
    
    @keyword
    def generate_zap_report(self, report_format='HTML', output_file='zap_report.html'):
        """Generate ZAP security report"""
        if not self.zap_enabled:
            self.builtin.log("ZAP proxy not enabled, skipping report generation", level='WARN')
            return "ZAP proxy not enabled"
        
        try:
            if report_format.upper() == 'HTML':
                zap_api_url = f"{self.zap_proxy}/OTHER/core/other/htmlreport/"
            elif report_format.upper() == 'XML':
                zap_api_url = f"{self.zap_proxy}/OTHER/core/other/xmlreport/"
            else:
                raise ValueError(f"Unsupported report format: {report_format}")
            
            params = {'apikey': self.zap_api_key}
            
            response = requests.get(zap_api_url, params=params)
            response.raise_for_status()
            
            # Ensure results directory exists
            results_dir = 'results'
            os.makedirs(results_dir, exist_ok=True)
            
            output_path = os.path.join(results_dir, output_file)
            
            with open(output_path, 'w', encoding='utf-8') as f:
                f.write(response.text)
            
            self.builtin.log(f"ZAP security report saved to: {output_path}", level='INFO')
            return output_path
        except Exception as e:
            raise Exception(f"Failed to generate ZAP report: {str(e)}")
    
    @keyword
    def verify_no_high_risk_vulnerabilities(self, base_url=None):
        """Verify that no high-risk vulnerabilities were found"""
        if not self.zap_enabled:
            self.builtin.log("ZAP proxy not enabled, skipping vulnerability check", level='WARN')
            return "ZAP proxy not enabled"
        
        try:
            alerts = self.get_zap_alerts(base_url)
            high_risk_alerts = [alert for alert in alerts if alert.get('risk', '').upper() == 'HIGH']
            
            if high_risk_alerts:
                high_risk_count = len(high_risk_alerts)
                alert_details = []
                
                for alert in high_risk_alerts[:5]:  # Show first 5 high-risk alerts
                    alert_details.append(
                        f"- {alert.get('name', 'Unknown')} "
                        f"(URL: {alert.get('url', 'Unknown')})"
                    )
                
                alert_summary = '\n'.join(alert_details)
                if high_risk_count > 5:
                    alert_summary += f"\n... and {high_risk_count - 5} more"
                
                raise AssertionError(
                    f"Found {high_risk_count} high-risk security vulnerabilities:\n{alert_summary}"
                )
            
            self.builtin.log("No high-risk vulnerabilities found", level='INFO')
            return "No high-risk vulnerabilities detected"
        except Exception as e:
            if "high-risk security vulnerabilities" in str(e):
                raise  # Re-raise assertion errors
            raise Exception(f"Failed to verify vulnerabilities: {str(e)}")
    
    @keyword
    def clear_zap_session(self):
        """Clear ZAP session data"""
        if not self.zap_enabled:
            return "ZAP proxy not enabled"
        
        try:
            zap_api_url = f"{self.zap_proxy}/JSON/core/action/newSession/"
            params = {'apikey': self.zap_api_key}
            
            response = requests.get(zap_api_url, params=params)
            response.raise_for_status()
            
            self.builtin.log("ZAP session cleared", level='INFO')
            return "ZAP session cleared"
        except Exception as e:
            raise Exception(f"Failed to clear ZAP session: {str(e)}")
