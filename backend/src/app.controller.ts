import { Controller, Get } from '@nestjs/common';

@Controller()
export class AppController {

  @Get()
  getHome() {
    return {
      project: 'AgroNexus',
      status: 'Running',
      version: '1.0.0'
    };
  }

  @Get('health')
  healthCheck() {
    return {
      status: 'healthy',
      timestamp: new Date()
    };
  }
}