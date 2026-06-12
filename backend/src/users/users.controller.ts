import { Body, Controller, Get, Post } from '@nestjs/common';
import { UsersService } from './users.service';
import { User } from './user.entity';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Post()
  createUser(@Body() data: Partial<User>) {
    return this.usersService.create(data);
  }

  @Get()
  getUsers() {
    return this.usersService.findAll();
  }
}