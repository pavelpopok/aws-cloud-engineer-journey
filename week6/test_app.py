import pytest

from app import app


@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client


def test_health_check(client):
    response = client.get("/api/wrong-path")
    assert response.status_code == 200


def test_home_page(client):
    response = client.get("/")
    assert response.status_code == 200
