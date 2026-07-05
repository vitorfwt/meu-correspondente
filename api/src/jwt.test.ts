import { describe, it, expect } from 'vitest';
import { generateToken, verifyToken, TokenPayload } from './utils/jwt.ts';
import jwt from 'jsonwebtoken';

describe('JWT Utility Unit Tests', () => {
  const payload: TokenPayload = {
    id: 'user-id-123',
    email: 'test@example.com',
    role: 'client',
  };

  it('should generate a token successfully', () => {
    const token = generateToken(payload);
    expect(token).toBeDefined();
    expect(typeof token).toBe('string');
    expect(token.split('.').length).toBe(3); // Formato JWT standard header.payload.signature
  });

  it('should successfully verify a valid generated token', () => {
    const token = generateToken(payload);
    const decoded = verifyToken(token);
    
    expect(decoded.id).toBe(payload.id);
    expect(decoded.email).toBe(payload.email);
    expect(decoded.role).toBe(payload.role);
  });

  it('should throw an error when verifying an invalid token', () => {
    expect(() => verifyToken('invalid-token-string')).toThrowError('Invalid token');
  });

  it('should throw an error when token signature is altered', () => {
    const token = generateToken(payload);
    const alteredToken = token + 'manipulated';
    expect(() => verifyToken(alteredToken)).toThrowError('Invalid token');
  });
});
