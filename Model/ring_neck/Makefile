VENV_DIR = .venv
PYTHON = python3

create_venv:
	$(PYTHON) -m venv $(VENV_DIR)
	@echo "Virtual environment created in $(VENV_DIR)"

enter_venv:
	@echo "To activate the virtual environment, run:"
	@echo "source $(VENV_DIR)/bin/activate"

install_requirements:
	$(PYTHON) -m pip install -r requirements.txt
