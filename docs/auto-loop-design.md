# Auto Loop Design

## 默认参数（必须一致）

- idea_loop `MAX_ITER=3`
- review_loop `MAX_ITER=4`
- figure_loop `MAX_ITER=5`
- citation_loop `MAX_ITER=3`

## 阈值

- idea-loop：任一候选 idea 分数 `>=80` 且 novelty 通过
- review-loop：综合分 `>=85` 且无 blocking issue
- figure-loop：所有图 `SCORE_THRESHOLD>=8.0`
- citation-loop：所有引用通过 Layer 1-3

## 终止条件

### idea-loop
- 达到通过阈值提前停止
- 或达到 `MAX_ITER=3`
- 每轮输出：`.arc/loop-logs/review-rounds/idea-round-{N}.json`

### review-loop
- 达到通过阈值提前停止
- 或达到 `MAX_ITER=4`
- 分数下降保护：连续两轮分数下降 -> `human-intervention-needed`
- 每轮输出：`.arc/loop-logs/review-rounds/review-round-{N}.json`

### figure-loop
- 全部图分达到阈值提前停止
- 或达到 `MAX_ITER=5`
- 每轮只修 top-3 问题，保留版本不覆盖
- 每轮输出：`.arc/loop-logs/figure-rounds/figure-round-{N}.json`

### citation-loop
- 全部通过 Layer 1-3 提前停止
- 或达到 `MAX_ITER=3`
- 每轮输出：`.arc/loop-logs/citation-rounds/citation-round-{N}.json`
- 低于 20 篇时发出补充提示

## 状态联动

`pipeline-status.json.loop_status` 必须同步维护：
- `current_round`
- `max_rounds`
- `best_score` / `score_history` / `verified_count` / `hallucinated_count`
- `status`：`not-started | running | completed | max-iter-reached | human-intervention-needed`
