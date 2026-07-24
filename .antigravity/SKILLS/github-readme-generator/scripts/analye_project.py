import os
import json
import sys

def analyze():
    project_info = {
        "language": "Unknown",
        "install_command": "README_MANUAL_INSTALL",
        "dependencies": []
    }
    
    # 1. 偵測 Node.js 專案
    if os.path.exists("package.json"):
        project_info["language"] = "JavaScript/TypeScript"
        project_info["install_command"] = "npm install"
        try:
            with open("package.json", "r", encoding="utf-8") as f:
                data = json.load(f)
                deps = list(data.get("dependencies", {}).keys())[:5]
                project_info["dependencies"] = deps
        except:
            pass
            
    # 2. 偵測 Python 專案
    elif os.path.exists("requirements.txt") or os.path.exists("pyproject.toml"):
        project_info["language"] = "Python"
        project_info["install_command"] = "pip install -r requirements.txt"
        if os.path.exists("requirements.txt"):
            try:
                with open("requirements.txt", "r", encoding="utf-8") as f:
                    deps = [line.strip().split("==")[0] for line in f if line.strip() and not line.startswith("#")][:5]
                    project_info["dependencies"] = deps
            except:
                pass
                
    # 3. 偵測 Rust 專案
    elif os.path.exists("Cargo.toml"):
        project_info["language"] = "Rust"
        project_info["install_command"] = "cargo build"
        
    return project_info

def main():
    try:
        info = analyze()
        # 輸出分析後的結構化 JSON，供 Antigravity Agent 讀取
        print(json.dumps(info, indent=2, ensure_ascii=False))
        sys.exit(0)
    except Exception as e:
        sys.stderr.write(f"Error analyzing project: {str(e)}\n")
        sys.exit(1)

if __name__ == "__main__":
    main()