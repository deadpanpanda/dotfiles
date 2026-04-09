function opt_orch_w --wraps='pnpm --filter @optizmo/optizmo-orchestration-worker go:dev:api' --description 'alias opt_orch_w pnpm --filter @optizmo/optizmo-orchestration-worker go:dev:api'
  pnpm --filter @optizmo/optizmo-orchestration-worker go:dev:api $argv
        
end
