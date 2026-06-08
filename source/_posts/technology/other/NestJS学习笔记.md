---
title: NestJS学习笔记
date: 2026-06-08 18:44:00
categories: 技术
tags:
- 后端开发
- NestJS
- TypeScript
---


# NestJS 学习笔记

> 本人（[youngqqcn](https://github.com/youngqqcn)）学习 NestJS 11 的实战总结。
> 项目：[hello_nest](https://github.com/youngqqcn/hello_nest) — 配套的"4 切面实战"学习项目。
>
> **读法**：每节尽量做到 5 分钟能读完；先看概念表格，再看代码片段；表格速记、代码查证。

---

## 📑 目录

- [NestJS 学习笔记](#nestjs-学习笔记)
  - [📑 目录](#-目录)
  - [1. 5 分钟速览：NestJS 是什么](#1-5-分钟速览nestjs-是什么)
  - [2. 核心概念：DI / 模块 / 装饰器](#2-核心概念di--模块--装饰器)
    - [2.1 依赖注入（DI）](#21-依赖注入di)
    - [2.2 模块（Module）](#22-模块module)
    - [2.3 装饰器 + reflect-metadata](#23-装饰器--reflect-metadata)
  - [3. 数据建模：Entity / DTO / VO](#3-数据建模entity--dto--vo)
    - [3.1 三种对象的关系](#31-三种对象的关系)
    - [3.2 DTO 验证（class-validator 风格）](#32-dto-验证class-validator-风格)
    - [3.3 DTO 验证（zod 4 风格）](#33-dto-验证zod-4-风格)
    - [3.4 class-validator vs zod 选型](#34-class-validator-vs-zod-选型)
    - [3.5 VO 响应脱敏（@Exclude + @Expose）](#35-vo-响应脱敏exclude--expose)
  - [4. 验证双轨：class-validator vs zod](#4-验证双轨class-validator-vs-zod)
    - [4.1 为什么可以并存](#41-为什么可以并存)
    - [4.2 接入方式对比](#42-接入方式对比)
    - [4.3 派生 PATCH DTO](#43-派生-patch-dto)
  - [5. 4 大切面：Middleware/Guard/Interceptor/Filter](#5-4-大切面middlewareguardinterceptorfilter)
    - [5.1 全景对比](#51-全景对比)
    - [5.2 Middleware（中间件）](#52-middleware中间件)
    - [5.3 Guard（守卫）](#53-guard守卫)
    - [5.4 Interceptor（拦截器）](#54-interceptor拦截器)
    - [5.5 Pipe（管道）](#55-pipe管道)
    - [5.6 Filter（异常过滤器）](#56-filter异常过滤器)
  - [6. 请求完整生命周期](#6-请求完整生命周期)
  - [7. 跨切面追踪：requestId 串联](#7-跨切面追踪requestid-串联)
  - [8. 自定义装饰器 3 件套](#8-自定义装饰器-3-件套)
  - [9. 踩过的 8 个真实坑](#9-踩过的-8-个真实坑)
  - [10. 项目当前结构](#10-项目当前结构)
  - [11. 常用命令](#11-常用命令)
  - [12. 下一步学习方向](#12-下一步学习方向)
  - [📚 推荐资源](#-推荐资源)

---

## 1. 5 分钟速览：NestJS 是什么

| 维度 | 解释 |
|---|---|
| **定位** | Node.js 后端框架，TypeScript-first，Angular 风格 |
| **设计哲学** | 借鉴 Spring / Angular：装饰器 + 强类型 + 关注点分离 |
| **核心抽象** | **Controller（路由） + Service（业务） + Module（装配）** |
| **生态地位** | Node 圈"重企业级"框架的代表；Express/Koa 是"轻量但裸" |
| **底层 HTTP** | 默认 Express，可切换 Fastify |
| **学习曲线** | 装饰器 + DI + 元数据编程这套心智模型建立后很简单 |

**它解决了什么**：

- ✅ 路由 + 参数解析 + 验证 + 鉴权 + 错误处理 + 响应序列化"全栈"集成
- ✅ 强类型从请求一路贯穿到数据库
- ✅ 通过装饰器 + 切面系统，**业务代码只关注业务**，横切关注（日志/鉴权/限流）由框架管
- ❌ 对比其他后端（如 Express 裸写），**有学习成本和"框架税"**

---

## 2. 核心概念：DI / 模块 / 装饰器

### 2.1 依赖注入（DI）

**核心**：类不自己 `new` 依赖，**声明"我需要什么"，让容器注入**。

```typescript
// ❌ 紧耦合
class AppController {
  constructor() { this.appService = new AppService(); }
}

// ✅ 松耦合
class AppController {
  constructor(private readonly appService: AppService) {}  // 容器自动注入
}
```

**为什么这样好**：

- 测试时能换成 Mock
- 改依赖实现不动 Controller
- "new 链"不再传染

**容器的工作方式**（简化伪代码）：

```typescript
class DIContainer {
  providers = new Map<Token, Instance>();
  get(token) { return this.providers.get(token); }
}
```

> 关键：NestJS 用 `reflect-metadata` 读出构造函数参数类型，再去容器查实现。

### 2.2 模块（Module）

**模块是"功能边界 + 装配单元"**：

```typescript
@Module({
  imports: [OtherModule],         // 依赖其他模块
  controllers: [XxxController],   // 注册路由
  providers: [XxxService],        // 注册可注入的类
  exports: [XxxService],          // 暴露给其他模块用
})
export class XxxModule {}
```

| 字段 | 作用 | 类比 |
|---|---|---|
| `imports` | 引入其他模块的导出 | JS 的 `import` |
| `controllers` | 这个模块有哪些 HTTP 入口 | API endpoint 注册表 |
| `providers` | 这个模块能注入什么 | 服务列表 |
| `exports` | 哪些 providers 暴露给其他模块 | 公共 API |

### 2.3 装饰器 + reflect-metadata

NestJS 几乎所有东西都是装饰器（`@Module`、`@Controller`、`@Injectable`、`@Get`...）。

**为什么能工作**：
- TypeScript 装饰器 + `emitDecoratorMetadata: true` 把类/方法的元数据写进编译产物
- NestJS 运行时用 `reflect-metadata` 读这些元数据
- 例：`@Controller('users')` 装饰器告诉 Nest "这个类是 /users 路径的处理器"

**tsconfig 必备**：

```json
{
  "experimentalDecorators": true,
  "emitDecoratorMetadata": true
}
```

---

## 3. 数据建模：Entity / DTO / VO

### 3.1 三种对象的关系

| 类型 | 方向 | 例子 | 关注点 |
|---|---|---|---|
| **Entity** | 内部 ↔ 数据库 | `{id, email, name, password, createdAt}` | 数据持久化 |
| **DTO** | 客户端 → 服务器 | `CreateUserDto` 接收的 `{email, name, password}` | 输入验证 |
| **VO** | 服务器 → 客户端 | `UserVo` 返回的 `{id, email, name}`（**无 password**） | 输出脱敏 |

**为什么要分**：

- DTO 拦截"客户端塞危险字段"（防 Mass Assignment）
- VO 拦截"服务器漏出敏感字段"（防 password 泄露）
- Entity 关心"数据库长什么样"

**不能用一个类同时做三件事**——会让"输入"和"输出"互相污染。

### 3.2 DTO 验证（class-validator 风格）

```typescript
import { IsEmail, IsString, MinLength } from 'class-validator';

export class CreateUserDto {
  @IsEmail({}, { message: 'email 格式不对' })
  email: string;

  @IsString()
  @MinLength(8)
  password: string;
}
```

接入：
```typescript
// 全局（main.ts）
app.useGlobalPipes(new ValidationPipe({
  whitelist: true,            // 剥离未声明字段
  forbidNonWhitelisted: true, // 多带字段直接 400
  transform: true,            // 自动转 DTO 实例 + URL 参数转 number
}));
```

**错误响应格式**：
```json
{ "message": ["email 格式不对"], "error": "Bad Request", "statusCode": 400 }
```

### 3.3 DTO 验证（zod 4 风格）

```typescript
import { z } from 'zod';
import { createZodDto } from 'nestjs-zod';

export const CreateBookSchema = z.object({
  title: z.string().min(1).max(200).toLowerCase(),
  isbn: z.string().regex(/^(\d{10}|\d{13})$/, { error: '必须是 ISBN-10/13' }),
  publishedYear: z.number().int().min(0).max(2030),
  pages: z.number().int().min(1).optional(),
});

export class CreateBookDto extends createZodDto(CreateBookSchema) {}
```

接入（**参数级**，不是方法级）：
```typescript
@Post()
create(@Body(new ZodValidationPipe(CreateBookSchema)) dto: CreateBookDto) { ... }
```

**错误响应格式**：
```json
{
  "statusCode": 400,
  "message": "Validation failed",
  "errors": [{
    "code": "invalid_type",
    "path": ["title"],
    "message": "Invalid input: expected string, received undefined"
  }]
}
```

### 3.4 class-validator vs zod 选型

| 维度 | class-validator | zod 4 |
|---|---|---|
| **风格** | OOP + 装饰器 | 函数式 + 链式 |
| **类型从哪来** | 手写 | **从 schema 自动推导** ⭐ |
| **错误格式** | 字符串数组 | 结构化对象（`code`/`path`/`message`） |
| **跨前后端** | 不行 | ✅ 同构（前后端共用 schema） |
| **前端友好** | 一般 | ✅（tRPC、TanStack Form、Astro 集成） |
| **学习曲线** | 装饰器会的人就熟 | 函数式 + 类型推导 |
| **推荐场景** | 纯 NestJS 后端 | 全栈 TS 项目、复杂 schema |

### 3.5 VO 响应脱敏（@Exclude + @Expose）

```typescript
import { Exclude, Expose } from 'class-transformer';

@Exclude()                       // 类级别：默认排除所有
export class UserVo {
  @Expose() id: number;          // 字段级别：白名单
  @Expose() email: string;
  // ⚠️ password 没声明 → 默认被剥除
  constructor(partial: Partial<UserVo>) { Object.assign(this, partial); }
}
```

接入（全局拦截器）：
```typescript
app.useGlobalInterceptors(new ClassSerializerInterceptor(app.get(Reflector)));
```

**Controller 用法**：
```typescript
@Post()
create(@Body() dto: CreateUserDto): UserVo {
  return new UserVo(this.usersService.create(dto));  // 内部对象转 VO 脱敏
}
```

**安全哲学**："默认拒绝 + 显式允许"——白名单优先于黑名单。

---

## 4. 验证双轨：class-validator vs zod

项目里两个模块**并存**：

```
users/  ← class-validator
books/  ← zod 4 + nestjs-zod 5.4
```

### 4.1 为什么可以并存

| 关键设计 | 说明 |
|---|---|
| `ValidationPipe` 不放全局 | 避免跟 books 局部的 ZodValidationPipe 冲突 |
| 各自的 Pipe 都挂 Controller 级 | 互不干扰 |
| `ClassSerializerInterceptor` 放全局 | 响应序列化两套都需要 |

### 4.2 接入方式对比

```typescript
// users/users.controller.ts —— class-validator
@Controller('users')
@UsePipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }))
export class UsersController { ... }

// books/books.controller.ts —— zod
@Controller('books')
export class BooksController {
  @Post()
  create(@Body(new ZodValidationPipe(CreateBookSchema)) dto: CreateBookDto) { ... }
}
```

### 4.3 派生 PATCH DTO

```typescript
// class-validator 风格
import { PartialType } from '@nestjs/mapped-types';
export class UpdateUserDto extends PartialType(CreateUserDto) {}

// zod 风格（一行，零依赖）
export const UpdateBookSchema = z.object(CreateBookSchema.shape).partial();
```

---

## 5. 4 大切面：Middleware/Guard/Interceptor/Filter

### 5.1 全景对比

| 维度 | Middleware | Guard | Interceptor | Pipe | Filter |
|---|---|---|---|---|---|
| **触发时机** | 最外层 | 路由后、handler 前 | handler 前后 | handler 前 | 异常时 |
| **能改 req/res** | ✅ | ❌ | ❌ | ❌ | ✅（写响应） |
| **能查 handler 元数据** | ❌ | ✅ | ✅ | ✅ | ✅ |
| **能改返回值** | ❌ | ❌ | ✅ | ❌ | ✅（包成错误） |
| **能拒绝请求** | ❌ | ✅ | ⚠️ | ❌ | ❌ |
| **接口** | `NestMiddleware` | `CanActivate` | `NestInterceptor` | `PipeTransform` | `ExceptionFilter` |
| **接入** | `configure()` | `@UseGuards()` | `@UseInterceptors()` | `@UsePipes()` / `@Body(new)` | `@Catch()` + `useGlobalFilters()` |
| **典型用途** | CORS、日志、限流 | JWT、角色、IP 白名单 | 缓存、响应包装、转换 | 参数验证、转换 | 异常兜底 |

### 5.2 Middleware（中间件）

**来源**：Express 风格，能直接用所有 Express 中间件（morgan/helmet/cors/cookie-parser...）

```typescript
@Injectable()
export class RequestLoggerMiddleware implements NestMiddleware {
  use(req: Request, res: Response, next: NextFunction) {
    const requestId = req.headers['x-request-id'] ?? randomUUID();
    req.requestId = requestId;
    const start = Date.now();
    res.on('finish', () => {
      const duration = Date.now() - start;
      console.log(`[${level}] [${requestId.slice(0,8)}] ${req.method} ${req.originalUrl} ${res.statusCode} ${duration}ms`);
    });
    next();
  }
}
```

**接入**：
```typescript
@Module({...})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer.apply(RequestLoggerMiddleware).forRoutes('*');
  }
}
```

### 5.3 Guard（守卫）

**核心**：决定"放不放"。能访问执行上下文（知道当前路由）。

```typescript
@Injectable()
export class AuthGuard implements CanActivate {
  constructor(private reflector: Reflector, private authService: AuthService) {}

  canActivate(context: ExecutionContext): boolean {
    // 1. @Public() 跳过
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(), context.getClass(),
    ]);
    if (isPublic) return true;

    // 2. 验证 API key
    const req = context.switchToHttp().getRequest();
    const apiKey = req.header('x-api-key');
    if (!apiKey) throw new UnauthorizedException('缺少 x-api-key header');

    const user = this.authService.findByApiKey(apiKey);
    if (!user) throw new UnauthorizedException('API Key 无效');

    // 3. 验证通过，把 user 塞到 req.user
    req.user = { id: user.id, name: user.name };
    return true;
  }
}
```

**接入（全局 + DI 友好）**：
```typescript
// AppModule
providers: [{ provide: APP_GUARD, useClass: AuthGuard }]
```

> ⚠️ 不要在 main.ts 用 `useGlobalGuards(new AuthGuard())` —— 无法注入 AuthService！

### 5.4 Interceptor（拦截器）

**核心**：用 RxJS Observable 把整个 handler 调用**包**起来，前后都能做事。

```typescript
@Injectable()
export class ResponseWrapperInterceptor implements NestInterceptor {
  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const requestId = context.switchToHttp().getRequest().requestId;
    const start = Date.now();
    return next.handle().pipe(
      map((data) => ({
        success: true,
        data,
        meta: { requestId, timestamp: new Date().toISOString(), duration: `${Date.now() - start}ms` },
      })),
    );
  }
}
```

**接入（全局）**：
```typescript
app.useGlobalInterceptors(new ResponseWrapperInterceptor());
```

**两个杀手级用法**：
- **响应包装**（如上）
- **缓存**：命中缓存直接 `return of(cachedData)` 跳过 handler

### 5.5 Pipe（管道）

你已经熟悉了：`ValidationPipe`、`ParseIntPipe`、`ZodValidationPipe`。**对单个参数做转换/验证**。

### 5.6 Filter（异常过滤器）

```typescript
@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost) {
    const requestId = host.switchToHttp().getRequest().requestId;
    const status = exception instanceof HttpException ? exception.getStatus() : 500;
    const code = this.codeFromStatus(status);

    response.status(status).json({
      success: false,
      error: { code, message, ...(details ? { details } : {}) },
      meta: { requestId, timestamp, path },
    });
  }
}
```

---

## 6. 请求完整生命周期

```
HTTP 请求
   ↓
1. RequestLoggerMiddleware          ← 塞 requestId、记 start
   ↓
2. AuthGuard                        ← @Public 跳过 / 验证 API key
   ↓
3. ResponseWrapperInterceptor      ← 前置（无）
   ↓
4. ValidationPipe / ZodValidationPipe  ← 验证参数
   ↓
5. Controller.method                ← 业务
   ↓
6. Service                          ← 业务
   ↓
7. ResponseWrapperInterceptor      ← 后置（包成 {success, data, meta}）
   ↓
8. RequestLoggerMiddleware          ← res.on('finish') 打日志
   ↓
HTTP 响应
   ↓
  异常时：
   ↓
AllExceptionsFilter                 ← 包成 {success, error, meta}
```

---

## 7. 跨切面追踪：requestId 串联

**关键洞察**：requestId 是个"接力棒"，在 4 切面间**靠 `req.requestId` 引用传递**。

| 切面 | 角色 |
|---|---|
| Middleware | 塞 `req.requestId` + `res.setHeader('x-request-id', ...)` |
| Guard | 不管 requestId |
| Controller | 通过 `@RequestId()` 装饰器拿 |
| Interceptor | 从 req 拿，包装到 `meta.requestId` |
| Filter | 从 req 拿，包到 `meta.requestId` + 服务端日志 |
| Middleware | `res.on('finish')` 打服务端日志 |

**客户端报错时拿到的 requestId → 发给服务端 → 搜日志 → 1 秒定位完整故事**。这就是 Sentry/Datadog 的简化版。

---

## 8. 自定义装饰器 3 件套

```typescript
// @Public() —— 标记"这个路由不需要鉴权"
export const IS_PUBLIC_KEY = 'isPublic';
export const Public = () => SetMetadata(IS_PUBLIC_KEY, true);

// @RequestId() —— 从 request 拿 requestId
export const RequestId = createParamDecorator((_, ctx) => {
  return ctx.switchToHttp().getRequest().requestId ?? 'unknown';
});

// @CurrentUser('id') —— 从 req.user 拿当前用户（可取子字段）
export const CurrentUser = createParamDecorator((data, ctx) => {
  const user = ctx.switchToHttp().getRequest().user;
  return data ? user?.[data] : user;
});
```

**注意类型扩展**——Express 默认不认 `req.requestId` 和 `req.user`：

```typescript
// src/types/express.d.ts
declare global {
  namespace Express {
    interface Request {
      requestId?: string;
      user?: { id: number; name: string };
    }
  }
}
```

---

## 9. 踩过的 8 个真实坑

| # | 现象 | 真因 | 教训 |
|---|---|---|---|
| 1 | `pnpm add` 后 IDE "Cannot find module" | pnpm 重新 link 延迟 | `Ctrl+Shift+P` → TypeScript: Restart TS Server |
| 2 | `tsc` 跟 IDE 错的不一致 | 两个独立进程 | **真错误以 `tsc` 为准** |
| 3 | `@UsePipes(ZodValidationPipe)` 失败 | class 引用找不到 DI 容器 | 用 `new ZodValidationPipe(schema)` 实例 |
| 4 | zod 4 用了 `error:` 报错 | nestjs-zod 4 还在用 `message:` | 当前是 zod 4 + nestjs-zod 5.4，用 `error:` |
| 5 | 全局 ValidationPipe 跟局部 ZodValidationPipe 冲突 | 全局 pipe 先跑破坏 body 格式 | 两套验证必须分离（一个 Controller 局部，一个参数级） |
| 6 | 方法级 `@UsePipes` PATCH 报"received string" | 方法级 pipe 对所有参数跑，**string "1" 也会被 zod 验证** | 用参数级 `@Body(new ZodValidationPipe(...))` |
| 7 | `CreateBookSchema.partial()` PATCH 失败 | zod 4 的 `.partial()` 派生 schema 行为异常 | 用 `z.object(CreateBookSchema.shape).partial()` 显式包一层 |
| 8 | 移除全局 ValidationPipe 后 URL 参数不再转 number | transform: true 是 ValidationPipe 提供的 | URL id 参数加 `@Param('id', ParseIntPipe)` |

---

## 10. 项目当前结构

```
src/
├── main.ts                          # 全局 ClassSerializerInterceptor + ResponseWrapper + AllExceptionsFilter
├── app.module.ts                    # imports: [UsersModule, BooksModule, AuthModule]
│                                   # APP_GUARD: AuthGuard（全局鉴权）
│                                   # configure(): RequestLoggerMiddleware
│
├── users/                           # class-validator 派
│   ├── users.controller.ts          # @UsePipes(new ValidationPipe({...}))
│   ├── dto/create-user.dto.ts       # @IsEmail/@MinLength 等装饰器
│   └── vo/user.vo.ts                # @Exclude 类 + @Expose 字段
│
├── books/                           # zod 派
│   ├── books.controller.ts          # @Body(new ZodValidationPipe(schema)) 参数级
│   ├── dto/create-book.dto.ts       # z.object({...}) schema
│   ├── dto/update-book.dto.ts       # z.object(CreateBookSchema.shape).partial()
│   └── vo/book.vo.ts                # @Exclude + @Expose 同 users
│
├── auth/                            # 演示鉴权
│   ├── auth.controller.ts           # @Public / @UseGuards / @CurrentUser
│   └── auth.service.ts              # 内存存储 "用户 → API key"
│
├── common/                          # 4 大切面
│   ├── middleware/request-logger.middleware.ts
│   ├── guards/auth.guard.ts
│   ├── interceptors/response-wrapper.interceptor.ts
│   ├── filters/all-exceptions.filter.ts
│   └── decorators/
│       ├── public.decorator.ts
│       ├── request-id.decorator.ts
│       └── current-user.decorator.ts
│
├── types/express.d.ts               # Express.Request 类型扩展
│
├── logger.service.ts                # 演示副产物
└── 两个 .spec.ts                    # jest 单元测试

scripts/
└── test-api.sh                      # 14 个端到端测试，验证 4 切面协作
```

---

## 11. 常用命令

```bash
# 开发
pnpm install                # 安装依赖
pnpm start:dev              # 启动 + watch（开发用这个）
pnpm test                   # 跑 jest
pnpm run lint               # ESLint
pnpm run format             # Prettier 自动格式化

# 端到端测试
bash scripts/test-api.sh    # 启动应用 + 14 个测试 + 汇总

# Git
git push                    # 推送到 GitHub
```

---

## 12. 下一步学习方向

按推荐顺序：

1. **配置管理** `@nestjs/config` —— 多环境 `.env.development/.env.production`
2. **接入数据库** —— TypeORM / Prisma，把 Service 接到真实 DB
3. **e2e 测试** —— 用 `@nestjs/testing` 给 BooksController 写完整测试
4. **Swagger / OpenAPI** —— 自动生成 API 文档
5. **微服务 / GraphQL** —— NestJS 不止能 REST

每个主题大概 30-60 分钟。

---

## 📚 推荐资源

- [NestJS 中文文档](https://docs.nestjs.cn/) — 官方中文版，质量高
- [NestJS 英文文档](https://docs.nestjs.com/) — 最新
- [zod.dev](https://zod.dev) — schema 验证 + 类型推导
- [class-validator](https://github.com/typestack/class-validator) — 装饰器验证
- [Conventional Commits](https://www.conventionalcommits.org/) — commit message 规范

---

**笔记维护者**：[youngqqcn](https://github.com/youngqqcn)
**最后更新**：见项目 git log
**项目地址**：[github.com/youngqqcn/hello_nest](https://github.com/youngqqcn/hello_nest)
