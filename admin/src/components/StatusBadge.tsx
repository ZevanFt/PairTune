import { Tag } from 'antd';

const colorMap: Record<string, string> = {
  active: 'green',
  disabled: 'red',
  exhausted: 'orange',
  pending: 'blue'
};

export function StatusBadge({ value }: { value: string }) {
  const color = colorMap[value] || 'blue';
  return <Tag color={color}>{value}</Tag>;
}
